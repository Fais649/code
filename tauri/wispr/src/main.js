const invoke = window.__TAURI__.core.invoke;
const threshold = 25;

const themes = [
	{ background: '#000', foreground: '#ddd' },
	{ background: '#d7d7d7', foreground: '#000' },
	{ background: '#1c2021', foreground: '#f9f5d7' },
	{ background: '#f9f5d7', foreground: '#1c2021' },
	{ background: '#d0d5e3', foreground: '#3860bf' },
	{ background: '#3860bf', foreground: '#d0d5e3' },
	{ background: '#f3f2fc', foreground: '#c590eb' },
	{ background: '#c590eb', foreground: '#f3f2fc' },
	{ background: '#fcf2ea', foreground: '#5b557e' },
	{ background: '#29243b', foreground: '#dedcf4' }
];

let currentIndex = parseInt(localStorage.getItem('themeIndex')) || 0;

window.addEventListener("DOMContentLoaded", async () => {
	await initializeApp();
});

async function initializeApp() {
	await setDateToToday();
	await loadContent(true);
	applyTheme(currentIndex);
	setupEventListeners();
	setupInputFocusIosHack();
}

function setupInputFocusIosHack() {
	document.addEventListener('focusin', function(event) {
		const focusElements = ['INPUT', 'TEXTAREA', 'SELECT'];
		if (focusElements.includes(event.target.tagName)) {
			const inputElement = event.target;
			inputElement.style.opacity = 0;
			setTimeout(() => {
				inputElement.style.opacity = 1;
			}, 0);
		}
	});
}

function setupEventListeners() {
	setupLogoEvents();
	setupDatePickerEvents();
	setupSaveEvents();
	setupTodoBoxEvents();
	setupNotesEvents();
}

function setupNotesEvents() {
	document.getElementById('note-textarea').addEventListener('focusout', async () => {
		await saveContent();
	})
}
function applyTheme(index) {
	const theme = themes[index];
	if (theme) {
		const root = document.documentElement;
		root.style.setProperty('--background-color-main', theme.background);
		root.style.setProperty('--foreground-color-main', theme.foreground);
	}
}

function setupLogoEvents() {
	const logo = document.querySelector("#logo");
	if (logo) {
		logo.addEventListener('pointerdown', () => {
			currentIndex = (currentIndex + 1) % themes.length;
			applyTheme(currentIndex);
			localStorage.setItem('themeIndex', currentIndex);
		});
	}
}

function setupDatePickerEvents() {
	const tomorrowBtn = document.querySelector(".tomorrow");
	const yesterdayBtn = document.querySelector(".yesterday");
	const dateEl = document.querySelector(".date");
	const dayOfWeekEl = document.querySelector("#dayOfWeek");

	if (tomorrowBtn) {
		tomorrowBtn.addEventListener("pointerdown", (e) => changeDateHandler(e, 1));
	}
	if (yesterdayBtn) {
		yesterdayBtn.addEventListener("pointerdown", (e) => changeDateHandler(e, -1));
	}
	if (dateEl) {
		dateEl.addEventListener("pointerdown", (e) => {
			e.preventDefault();
			toggleCalendar();
		});
	}
	if (dayOfWeekEl) {
		dayOfWeekEl.addEventListener("pointerdown", async (e) => {
			e.preventDefault();
			await saveContent();
			await setDateToToday();
			await loadContent();
		});
	}
}

async function changeDateHandler(e, direction) {
	e.preventDefault();
	const dateEl = document.querySelector(".date");
	try {
		await saveContent();
		await changeDate(dateEl.textContent, direction);
		await loadContent();
	} catch (error) {
		console.error("Error during date change:", error);
		alert("An error occurred while changing the date.");
	}
}

function setupSaveEvents() {
	const saveBtn = document.querySelector("#save-btn");
	if (saveBtn) {
		saveBtn.addEventListener("pointerdown", async (e) => {
			e.preventDefault();
			try {
				const result = await saveContent();
				if (result !== "SAVED") {
					console.error("Unexpected save result:", result);
					alert("An unexpected error occurred while saving content.");
				}
			} catch (error) {
				console.error("Error saving content:", error);
				alert("An error occurred while saving content.");
			}
		});
	}
}

function setupTodoBoxEvents() {
	const addTodoBtn = document.querySelector("#add-todo-btn");
	const todoList = document.querySelector("#todo-list");

	if (addTodoBtn) {
		addTodoBtn.addEventListener("pointerdown", async (e) => {
			e.preventDefault();
			await handleAddTodo();
		});
	}

	if (todoList) {
		todoList.addEventListener("pointerdown", async (e) => {
			if (e.target === todoList) {
				e.preventDefault();
				await handleAddTodo();
			}
		});
	}
}

async function handleAddTodo() {
	try {
		const result = await addTodo();
		if (result !== "yes") {
			console.error("Unexpected add-todo result:", result);
			alert("An unexpected error occurred while adding a todo.");
		}
	} catch (error) {
		console.error("Error adding todo:", error);
		alert("An error occurred while adding a todo.");
	}
}

function handleSwipeEnd(diffX, element) {
	console.log(diffX);
	if (diffX < -threshold) {
		element.style.transition = 'transform 0.1s ease';
		element.style.transform = 'translateX(-100%)';
		setTimeout(() => {
			element.remove();
		}, 500);
	} else if (diffX > 20) {
		console.log('madeit')
		const childElement = element.querySelector('.todo-item-text');
		if (childElement) {
			element.classList.toggle("expand");
			childElement.classList.toggle("expand");
		}
		element.style.transition = 'transform 0.3s ease';
		element.style.transform = 'translateX(0)';
	} else {
		element.style.transition = 'transform 0.3s ease';
		element.style.transform = 'translateX(0)';
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

function setDayOfWeek(dateString) {
	const dayOfWeekEl = document.querySelector("#dayOfWeek");
	const date = new Date(dateString);
	const weekday = date.toLocaleDateString('en-US', { weekday: 'short' });
	dayOfWeekEl.textContent = weekday;
}

async function changeDate(currentDate, direction) {
	const dateEl = document.querySelector(".date");
	try {
		const date = await invoke("change_current_date", { date: currentDate, direction: direction });
		dateEl.textContent = date;
		setDayOfWeek(date);
	} catch (error) {
		console.error("Error changing date:", error);
		dateEl.textContent = "Failed to fetch date.";
	}
}

async function saveContent() {
	let filename = document.querySelector(".date").textContent.trim();

	if (!filename.toLowerCase().endsWith('.json')) {
		filename += '.json';
	}

	const jsonString = stringifySaveFileContent();
	try {
		return await invoke("save_content", { filename: filename, content: jsonString });
	} catch (error) {
		console.error("Error saving content:", error);
		alert("An unexpected error occurred while saving content.");
		throw error;
	}
}

function stringifySaveFileContent() {
	const todoItems = Array.from(document.querySelectorAll("li.todo-item-text"));
	const todo = {};

	todoItems.forEach((item, index) => {
		todo[index] = {
			content: item.textContent,
			done: item.classList.contains("done"),
			expand: item.classList.contains("expand")
		};
	});

	const note = document.querySelector("#note-textarea").value;

	return JSON.stringify({ todo, note }, null, 2);
}

async function loadContent(first = false) {
	const todo = document.getElementById("todo-list");
	todo.innerHTML = "";
	let filename = "";

	if (first) {
		filename = await invoke("get_today_date");
	} else {
		const dateEl = document.querySelector(".date");
		filename = dateEl ? dateEl.textContent.trim() : "";
	}

	if (!filename.toLowerCase().endsWith('.json')) {
		filename += '.json';
	}

	try {
		const content = await invoke("load_content", { filename });
		if (!content) {
			document.querySelector("#note-textarea").value = "";
			return;
		}
		await parseLoadedFileContent(content);
	} catch (error) {
		console.error("Error loading content:", error);
		alert("An unexpected error occurred while loading content.");
	}
}

async function parseLoadedFileContent(content) {
	let contentJson;
	try {
		contentJson = JSON.parse(content);
	} catch (parseError) {
		console.error("Failed to parse JSON:", parseError);
		alert("Failed to parse JSON content.");
		return;
	}

	const todoList = document.getElementById("todo-list");
	const note = document.querySelector("#note-textarea");

	if (todoList && note) {
		for (const [key, todo] of Object.entries(contentJson.todo)) {
			await loadTodoListItem(todoList, key, todo.content, todo.done, todo.expand);
		}
		note.value = contentJson.note || "";
	} else {
		console.error("Todo list or note elements not found.");
		alert("Todo list or note elements not found.");
	}
}

async function loadTodoListItem(todoList, todoCount, content = "", done = false, expand = false) {
	if (content.length === 0) return;
	await createTodoItem(todoList, todoCount, 'li', content, done, expand);
}

async function addTodo() {
	const todoList = document.querySelector(".todo-list");
	const todoCount = todoList.children.length;

	const existingInput = todoList.querySelector("input.todo-item-text");
	if (existingInput) {
		existingInput.focus();
		return "yes";
	}

	return await createTodoItem(todoList, todoCount, 'input');
}

async function createTodoItem(todoList, todoCount, type = 'li', content = "", done = false, expand = false) {
	const todoItem = document.createElement('div');
	todoItem.classList.add("todo-item");
	todoItem.id = `todo-item-${todoCount}`;

	const box = createCheckBox(todoCount, done);
	todoItem.appendChild(box);

	let todoItemText;
	if (type === 'input') {
		todoItemText = document.createElement('input');
		todoItemText.type = 'text';
	} else {
		todoItemText = document.createElement('li');
	}

	todoItemText.classList.add("todo-item-text");
	if (done) todoItemText.classList.add("done");
	if (expand) {
		todoItemText.classList.add("expand");
		todoItem.classList.add("expand");
	}

	if (content) {
		if (type === 'input') {
			todoItemText.value = content;
		} else {
			todoItemText.textContent = content;
		}
	}

	if (type === 'input') {
		addTodoInputEvents(todoItemText);
	} else {
		addSwipeToDeleteEventListeners(todoItem);
		addExpandEventListener(todoItemText);
	}

	todoItemText.style.opacity = 0;
	setTimeout(() => {
		todoItemText.style.opacity = 1;
	}, 0);
	todoItem.appendChild(todoItemText);
	todoList.appendChild(todoItem);
	todoItem.scrollIntoView();
	todoItemText.focus();

	return "yes";
}

function addTodoInputEvents(todoItemText) {
	todoItemText.addEventListener('keypress', async (e) => {
		if (e.key === 'Enter') {
			await finalizeTodoInput(todoItemText);
		}
	});

	todoItemText.addEventListener('focusin', () => {
		todoItemText.style.opacity = 0;
		setTimeout(() => {
			todoItemText.style.opacity = 1;
		}, 0);
	});
	todoItemText.addEventListener('focusout', async () => {
		await finalizeTodoInput(todoItemText);
	});
}

function toggleTodoInput(todoItemText) {
	const itemNew = document.createElement('input');
	itemNew.id = todoItemText.id;
	itemNew.value = todoItemText.innerText;
	itemNew.classList = todoItemText.classList;
	todoItemText.parentNode.replaceChild(itemNew, todoItemText);
	itemNew.classList.remove('expand');
	itemNew.parentElement.classList.remove('expand');
	itemNew.style.opacity = 0;
	setTimeout(() => {
		itemNew.style.opacity = 1;
	}, 0);
	addTodoInputEvents(itemNew)
	addExpandEventListener(itemNew)
	itemNew.focus();
}

async function finalizeTodoInput(todoItemText) {
	if (todoItemText.value.trim().length > 0) {
		const itemNew = document.createElement('li');
		itemNew.id = todoItemText.id;
		itemNew.textContent = todoItemText.value;
		itemNew.classList = todoItemText.classList;

		addSwipeToDeleteEventListeners(todoItemText.parentNode);
		addExpandEventListener(itemNew);

		todoItemText.parentNode.replaceChild(itemNew, todoItemText);
	} else {
		todoItemText.parentNode.remove();
	}
	await saveContent();
}

function addSwipeToDeleteEventListeners(todoItem) {
	let isDragging = false;
	let startX = 0;
	let currentX = 0;

	todoItem.addEventListener('pointerdown', function(event) {
		isDragging = true;
		startX = event.clientX;
		currentX = startX;
		todoItem.setPointerCapture(event.pointerId);
	}, false);

	todoItem.addEventListener('pointermove', function(event) {
		if (!isDragging) return;
		currentX = event.clientX;
		let diffX = currentX - startX;
		todoItem.style.transform = `translateX(${diffX}px)`;
	}, false);

	todoItem.addEventListener('pointerup', function(event) {
		if (!isDragging) return;
		isDragging = false;
		let diffX = currentX - startX;
		handleSwipeEnd(diffX, todoItem);
		todoItem.releasePointerCapture(event.pointerId);
	}, false);

	todoItem.addEventListener('pointercancel', function(event) {
		if (isDragging) {
			isDragging = false;
			let diffX = currentX - startX;
			handleSwipeEnd(diffX, todoItem);
			todoItem.style.transition = 'transform 0.1s ease';
			todoItem.style.transform = 'translateX(0)';
		}
		todoItem.releasePointerCapture(event.pointerId);
	}, false);
}

function addExpandEventListener(todoItemText) {
	todoItemText.addEventListener('click', async (e) => {
		e.preventDefault();

		toggleTodoInput(todoItemText);
	});
}

function createCheckBox(todoCount, done = false) {
	const box = document.createElement('label');
	box.textContent = done ? '[x]' : '[ ]';
	box.id = `box-todo-item-${todoCount}`;
	box.classList.add("box-todo-item");
	box.addEventListener("pointerdown", async (e) => {
		e.preventDefault();
		await toggleCheckTodoEvent(box);
	});
	return box;
}

async function toggleCheckTodoEvent(box) {
	const parentElement = box.parentElement;
	if (parentElement) {
		const todoText = parentElement.querySelector(".todo-item-text");
		if (todoText) {
			if (todoText.classList.contains("done")) {
				box.textContent = '[ ]';
				todoText.classList.remove("done");
			} else {
				box.textContent = '[x]';
				todoText.classList.add("done");
			}
			await saveContent();
		} else {
			console.error("Todo text element not found.");
		}
	} else {
		console.error("Parent element not found.");
	}
}
