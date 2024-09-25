const invoke = window.__TAURI__.core.invoke;

window.addEventListener("DOMContentLoaded", () => {
  setDateToToday();
  loadContent(true);

  setupDatePickerEvents();
  setupSaveEvents();
  setupTodoBoxEvents();

  document.querySelectorAll(".text").forEach((focused) => {
    focused.addEventListener("focus", () => {
      focused.style.opacity = 0;
      setTimeout(() => focused.style.opacity = 1);
    });
  });
});

function setupDatePickerEvents() {
  document.querySelector(".tomorrow").addEventListener("click", async (e) => {
    e.preventDefault();
    const dateEl = document.querySelector(".date");

    try {
      await saveContent();
      await changeDate(dateEl.textContent, 1);
      await loadContent();
    } catch (error) {
      console.error("Error during date change:", error);
      alert("An error occurred while changing the date.");
    }
  });

  document.querySelector(".yesterday").addEventListener("click", async (e) => {
    e.preventDefault();

    const dateEl = document.querySelector(".date");
    try {
      await saveContent();
      await changeDate(dateEl.textContent, -1);
      await loadContent();
    } catch (error) {
      console.error("Error during date change:", error);
      alert("An error occurred while changing the date.");
    }
  });

  document.querySelector(".date").addEventListener("click", async (e) => {
    e.preventDefault();
    await toggleCalendar();
  });

  document.querySelector("#dayOfWeek").addEventListener("click", async (e) => {
    e.preventDefault();
    await saveContent();
    await setDateToToday();
    await loadContent();
  });
}

function setupSaveEvents() {
  document.querySelector(".save").addEventListener("click", async (e) => {
    e.preventDefault();
    try {
      const result = await saveContent();
      if (result === "SAVED") {
      } else {
        console.error("Unexpected save result:", result);
        alert("An unexpected error occurred while saving content.");
      }
    } catch (error) {
      console.error("Error saving content:", error);
      alert("An error occurred while saving content.");
    }
  });
}


function setupTodoBoxEvents() {
  document.querySelector(".add-todo").addEventListener("click", async (e) => {
    e.preventDefault();
    try {
      const result = await addTodo();
      if (result === "yes") {
      } else {
        console.error("Unexpected add-todo result:", result);
        alert("An unexpected error occurred while saving content.");
      }
    } catch (error) {
      console.error("Error saving content:", error);
      alert("An error occurred while saving content.");
    }
  });


  document.querySelectorAll(".box-todo-item").forEach((boxItem) => {
    boxItem.addEventListener("click", async (e) => {
      e.preventDefault();
      toggleCheckTodoEvent(e);
    });
  });

  document.querySelectorAll(".todo-item").forEach((item) => {
    let item_text = item.querySelector(".todo-item-text");
    item_text.addEventListener('keypress', async (e) => {
      if (e.key === 'Enter') {
        let item_new = document.createElement('li');
        item_new.id = item_text.id
        item_new.innerText = item_text.value;
        item_new.classList = item_text.classList;
        await addExpandEventListener(item_new)
        item_text.parentNode.replaceChild(item_new, item_text);
      }
    });
  });
}

async function toggleCheckTodoEvent(box) {
  const parentElement = box.parentElement;
  console.log('clicked box');
  if (parentElement) {
    const todo_text = parentElement.querySelector(".todo-item-text");
    if (todo_text.classList.contains("done")) {
      box.innerText = '[ ]';
      todo_text.classList.remove("done");
    } else {
      box.innerText = '[x]'
      todo_text.classList.add("done");
    }

    console.log("Parent element removed successfully.");
    await saveContent();
  } else {
    console.error("Parent element not found.");
    alert("Unable to delete the item. Parent element not found.");
  }
}

async function setDateToToday() {
  const dateEl = document.querySelector(".date");

  try {
    const todayDate = await invoke("get_today_date");
    setDayOfWeek(todayDate);
    dateEl.textContent = todayDate;
    await invoke("load_content", { filename: todayDate });
  } catch (error) {
    console.error("Error invoking get_today_date command:", error);
    dateEl.textContent = "Failed to fetch date.";
  }
}

async function setDayOfWeek(dateString) {
  const dayOfWeekEl = document.querySelector("#dayOfWeek");
  let date = new Date(dateString);
  const weekday = date.toLocaleDateString('en-US', { weekday: 'short' });

  dayOfWeekEl.textContent = weekday;
}

async function changeDate(currentDate, direction) {
  const dateEl = document.querySelector(".date");
  try {
    const date = await invoke("change_current_date", { date: currentDate, direction: direction });
    dateEl.textContent = date;
    await setDayOfWeek(date);
  } catch (error) {
    console.error("Error invoking get_today_date command:", error);
    dateEl.textContent = "Failed to fetch date.";
  }
}

async function saveContent() {
  let filename = document.querySelector(".date").textContent.trim();

  if (!filename.toLowerCase().endsWith('.json')) {
    filename += '.json';
  }

  const jsonString = stringifySaveFileContent();
  console.log(jsonString);
  try {
    const result = await invoke("save_content", { filename: filename, content: jsonString });
    return result;
  } catch (error) {
    console.error("Error saving content:", error);
    alert("An unexpected error occurred while saving content.");
    throw error;
  }
}

function stringifySaveFileContent() {
  let i = 0;
  let todo_items_content = {};
  document.querySelectorAll("li.todo-item-text").forEach((todo_item_content) => {
    console.log("saving");
    console.log(todo_item_content.textContent);
    todo_items_content[i] = { "content": todo_item_content.textContent, "done": todo_item_content.classList.contains("done") ? true : false, "expand": todo_item_content.classList.contains("expand") ? true : false };
    i++;
  });

  let todo = todo_items_content;
  let note = document.querySelector("#text-note");

  let jsonArray = {
    "todo": todo,
    "note": note.value
  }

  let jsonString = JSON.stringify(jsonArray, null, 2).toString();

  return jsonString;
}

async function loadContent(first = false) {
  const todo = document.getElementById("todo-list");
  todo.innerHTML = "";
  let filename = "";

  if (first) {
    filename = await invoke("get_today_date");
    if (!filename) {
      console.error("Filename not found.");
      alert("Filename not found.");
      return;
    }
  } else {
    const filenameElement = document.querySelector(".date");
    if (!filenameElement) {
      console.error("Filename element not found.");
      alert("Filename element not found.");
      return;
    }

    filename = filenameElement.textContent.trim();
  }

  if (!filename.toLowerCase().endsWith('.json')) {
    filename += '.json';
  }

  try {
    const content = await invoke("load_content", { filename });

    if (!content) {
      console.log("no content");
      const note = document.querySelector("#text-note");

      if (todo && note) {
        todo.innerHTML = "";
        note.value = "";
      } else {
        console.error("Todo or Note elements not found.");
        alert("Todo or Note elements not found.");
      }
      return;
    }

    await parseLoadedFileContent(content);
  } catch (error) {
    console.error("Error invoking load_content:", error);
    alert("An unexpected error occurred while loading content.");
  }
}

async function parseLoadedFileContent(content) {
  console.log("parse content");
  let contentJson;
  try {
    contentJson = JSON.parse(content);
  } catch (parseError) {
    console.error("Failed to parse JSON:", parseError);
    alert("Failed to parse JSON content.");
    return;
  }

  console.log(contentJson.todo);
  const todo_list = document.getElementById("todo-list");
  const note = document.querySelector("#text-note");

  if (todo_list && note) {
    console.log(contentJson.todo);
    Object.entries(contentJson.todo).forEach(async ([key, todo]) => {
      await loadTodoListItem(todo_list, key, todo.content, todo.done, todo.expand);
    });

    note.value = contentJson.note || "";
  } else {
    console.error("Todo or Note elements not found.");
    alert("Todo or Note elements not found.");
  }
}

async function loadTodoListItem(todo_list, todo_count, content = "", done = false, expand = false) {
  if (content.length == 0) {
    return;
  }

  await createTodo(todo_list, todo_count, 'li', content, done, expand);
  return "yes"
}

async function addTodo() {
  let todo_list = document.querySelector(".todo-list");
  let todo_count = todo_list.children.length;
  let has_input = false;

  let input = document.querySelectorAll("input.todo-item-text");
  console.log(input.length);
  if (input.length > 0) {
    let todo_input = input[0];
    todo_input.scrollIntoView();
    todo_input.focus();
    has_input = true;
    return "yes";
  }

  return createTodo(todo_list, todo_count, 'input');
}

async function addExpandEventListener(todo_item_text) {
  todo_item_text.addEventListener('click', async (e) => {
    e.preventDefault();
    console.log("clik");
    if (!todo_item_text.classList.contains("expand")) {
      todo_item_text.classList.add("expand");
      todo_item_text.parentElement.classList.add("expand");
      todo_item_text.scrollIntoView();
    } else {
      todo_item_text.classList.remove("expand");
      todo_item_text.parentElement.classList.remove("expand");
    }
    await saveContent();
  });
}


async function createTodo(todo_list, todo_count, type = 'li', content = "", done = false, expand = false) {
  let todo_item = document.createElement('div');
  todo_item.classList.add("todo-item");
  todo_item.id = `todo-item-${todo_count}`
  const box = await createCheckBox(todo_count, done);
  todo_item.appendChild(box);

  let todo_item_text = document.createElement(type);
  if (done) {
    todo_item_text.classList.add("todo-item-text", "done");
  } else {
    todo_item_text.classList.add("todo-item-text");
  }
  todo_item_text.addEventListener("focus", () => {
    todo_item_text.style.opacity = 0;
    setTimeout(() => todo_item_text.style.opacity = 1);
  });

  if (expand) {
    todo_item_text.classList.add("expand");
    todo_item.classList.add("expand");
  }

  if (type == 'input') {
    todo_item_text.addEventListener('keypress', async (e) => {
      if (e.key === 'Enter') {
        let item_new = document.createElement('li');
        item_new.id = todo_item_text.id
        item_new.innerText = todo_item_text.value;
        item_new.classList = todo_item_text.classList;
        await addExpandEventListener(item_new);
        todo_item_text.parentNode.replaceChild(item_new, todo_item_text);
      }
    });
  } else {
    await addExpandEventListener(todo_item_text);
  }

  if (content.length > 0 && type == 'li') {
    todo_item_text.innerText = content;
  }

  todo_item.appendChild(todo_item_text);
  todo_list.appendChild(todo_item);
  todo_item.scrollIntoView();
  todo_item_text.focus();

  return "yes";
}

async function createCheckBox(todo_count, done = false) {
  let box = document.createElement('label');
  console.log(done);
  box.innerText = done ? '[x]' : '[ ]';
  box.id = `box-todo-item-${todo_count}`;
  box.classList.add("box-todo-item");
  box.addEventListener("click", async (e) => {
    e.preventDefault();
    await toggleCheckTodoEvent(box);
  });
  return box;
}

async function toggleCalendar() {
  let calendar = document.querySelector("#calendar");
}
