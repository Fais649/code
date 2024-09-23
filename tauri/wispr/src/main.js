const invoke = window.__TAURI__.core.invoke;

window.addEventListener("DOMContentLoaded", () => {
  fetchTodayDate();
  loadContent(true);

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
  })

  document.querySelector(".save").addEventListener("click", async (e) => {
    e.preventDefault();
    try {
      const result = await saveContent();
      if (result === "SAVED") {
        //alert("Content saved successfully!");
      } else {
        console.error("Unexpected save result:", result);
        alert("An unexpected error occurred while saving content.");
      }
    } catch (error) {
      console.error("Error saving content:", error);
      alert("An error occurred while saving content.");
    }
  });

  document.querySelector(".add-todo").addEventListener("click", async (e) => {
    e.preventDefault();
    try {
      const result = await addTodo();
      if (result === "yes") {
        //alert("todo added");
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
    boxItem.addEventListener("click", (e) => {
      e.preventDefault();
      const parentElement = boxItem.parentElement;
      console.log('clicked box');

      if (parentElement) {
        parentElement.remove();
        console.log("Parent element removed successfully.");

        // Optional: Update the underlying data or save changes
        // await saveContent(); // If using async function and saveContent is defined
      } else {
        console.error("Parent element not found.");
        alert("Unable to delete the item. Parent element not found.");
      }
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
        item_text.parentNode.replaceChild(item_new, item_text);
      }
    });
  });

  const box = document.querySelector('.box.note');
  const body = document.body;
  const toggleDimmed = () => {
    if (box.contains(document.activeElement)) {
      body.classList.add('dimmed');
    } else {
      body.classList.remove('dimmed');
    }
  };

  document.querySelectorAll(".text").forEach((focused) => {
    focused.addEventListener("focus", () => {
      focused.style.opacity = 0;
      setTimeout(() => focused.style.opacity = 1);
      alert("focused");
    });
  });

  document.addEventListener('focusin', toggleDimmed);
  document.addEventListener('focusout', toggleDimmed);

  toggleDimmed();
});

async function fetchTodayDate() {
  const dateEl = document.querySelector(".date");

  try {
    const todayDate = await invoke("get_today_date");
    dateEl.textContent = todayDate;
    await invoke("load_content", { filename: todayDate });
  } catch (error) {
    console.error("Error invoking get_today_date command:", error);
    dateEl.textContent = "Failed to fetch date.";
  }
}

async function changeDate(currentDate, direction) {
  const dateEl = document.querySelector(".date");
  try {
    const date = await invoke("change_current_date", { date: currentDate, direction: direction });
    dateEl.textContent = date;
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

  let i = 0;
  let todo_items_content = {};
  document.querySelectorAll("li.todo-item-text").forEach((todo_item_content) => {
    console.log(todo_item_content.textContent);
    todo_items_content[i] = todo_item_content.textContent;
    i++;
  });

  let todo = todo_items_content;
  let note = document.querySelector("#text-note");

  let jsonArray = {
    "todo": todo,
    "note": note.value
  }

  let jsonString = JSON.stringify(jsonArray, null, 2).toString();

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

    console.log("content");
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
      Object.entries(contentJson.todo).forEach(([key, todoText]) => {
        createTodoListItem(todo_list, key, todoText);
      });

      note.value = contentJson.note || "";
    } else {
      console.error("Todo or Note elements not found.");
      alert("Todo or Note elements not found.");
    }
  } catch (error) {
    console.error("Error invoking load_content:", error);
    alert("An unexpected error occurred while loading content.");
  }
}

function createTodoListItem(todo_list, key, todoText = "") {
  let todo_item = document.createElement('div');
  todo_item.classList.add("todo-item");
  todo_item.id = `todo-item-${key}`;

  let box = document.createElement('label');
  box.innerText = '[ ]';
  box.id = `box-todo-item-${key}`;
  box.classList.add("box-todo-item");

  box.addEventListener("click", async (e) => {
    e.preventDefault();
    const parentElement = box.parentElement;
    console.log('clicked box');

    if (parentElement) {
      parentElement.remove();
      console.log("Parent element removed successfully.");

      await saveContent(); // If using async function and saveContent is defined
    } else {
      console.error("Parent element not found.");
      alert("Unable to delete the item. Parent element not found.");
    }
  });

  todo_item.appendChild(box);

  let type = todoText.length > 0 ? 'li' : 'input';
  let todo_item_text = document.createElement(type);
  todo_item_text.classList.add("todo-item-text");
    todo_item_text.addEventListener("focus", () => {
      todo_item_text.style.opacity = 0;
      setTimeout(() => todo_item_text.style.opacity = 1);
      alert("focused");
    });

  if (todoText.length > 0) {
    todo_item_text.innerText = todoText;
  }

  todo_item.appendChild(todo_item_text);
  todo_list.appendChild(todo_item);

  console.log(`Added todo item ${key}: ${todoText}`);
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

  let todo_item = document.createElement('div');
  todo_item.classList.add("todo-item");
  todo_item.id = `todo-item-${todo_count}`

  let box = document.createElement('label');
  box.innerText = '[ ]';
  box.id = `box-todo-item-${todo_count}`;
  box.classList.add("box-todo-item");

  box.addEventListener("click", async (e) => {
    e.preventDefault();
    const parentElement = box.parentElement;
    console.log('clicked box');

    if (parentElement) {
      parentElement.remove();
      console.log("Parent element removed successfully.");

      await saveContent(); // If using async function and saveContent is defined
    } else {
      console.error("Parent element not found.");
      alert("Unable to delete the item. Parent element not found.");
    }
  });

  todo_item.appendChild(box);
  let todo_item_text = document.createElement('input');
  todo_item_text.classList.add("todo-item-text");
    todo_item_text.addEventListener("focus", () => {
      todo_item_text.style.opacity = 0;
      setTimeout(() => todo_item_text.style.opacity = 1);
      alert("focused");
    });
  todo_item_text.addEventListener('keypress', async (e) => {
    if (e.key === 'Enter') {
      let item_new = document.createElement('li');
      item_new.id = todo_item_text.id
      item_new.innerText = todo_item_text.value;
      item_new.classList = todo_item_text.classList;
      todo_item_text.parentNode.replaceChild(item_new, todo_item_text);
    }
  });

  todo_item.appendChild(todo_item_text);

  todo_list.appendChild(todo_item);
  todo_item.scrollIntoView();
  todo_item_text.focus();
  return "yes";
}
