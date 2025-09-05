<template>
  <div class="todo-app">
    <h1>Todo App</h1>
    <div class="layout-row">
      <div class="panel form-panel">
        <form @submit.prevent="addTodo">
          <label class="field">
            <span class="field-label">Title</span>
            <input v-model="newTodo.title" placeholder="Title" required />
          </label>

          <label class="field">
            <span class="field-label">Priority</span>
            <select v-model="newTodo.priority" required>
              <option disabled value="">Priority</option>
              <option>Low</option>
              <option>Medium</option>
              <option>High</option>
            </select>
          </label>

          <label class="field">
            <span class="field-label">Due Date</span>
            <input type="date" v-model="newTodo.dueDate" required />
          </label>

          <label class="field">
            <span class="field-label">Description</span>
            <textarea v-model="newTodo.description" placeholder="Description" required></textarea>
          </label>

          <div class="actions">
            <button type="submit">Add Todo</button>
          </div>
        </form>
      </div>

      <div class="panel list-panel">
        <ul class="todo-list">
          <li v-for="(todo, idx) in todos" :key="todo.id" :class="['priority-' + todo.priority.toLowerCase()]">
            <div class="todo-header">
              <div class="title-block">
                <strong class="title">{{ todo.title }}</strong>
                <span class="priority">[{{ todo.priority }}]</span>
              </div>
              <div class="controls">
                <span class="due-date">Due: {{ todo.dueDate }}</span>
                <button @click="removeTodo(idx)">Delete</button>
                <button @click="rewriteAsPirate(idx)" :disabled="loadingIdx === idx">{{ loadingIdx === idx ? 'Rewriting...' : 'Rewrite as Pirate' }}</button>
              </div>
            </div>
            <div class="description">{{ todo.description }}</div>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'

const todos = ref([])
const newTodo = ref({
  title: '',
  priority: '',
  dueDate: '',
  description: ''
})
// Always use gpt-5-nano
const fixedModel = "gpt-5-nano"
const loadingIdx = ref(null)

onMounted(() => {
  const saved = localStorage.getItem('todos')
  if (saved) todos.value = JSON.parse(saved)
  // Optionally, fetch models from backend
})

watch(todos, (val) => {
  localStorage.setItem('todos', JSON.stringify(val))
}, { deep: true })

function addTodo() {
  if (!newTodo.value.title || !newTodo.value.priority || !newTodo.value.dueDate || !newTodo.value.description) return
  todos.value.push({
    ...newTodo.value,
    id: Date.now()
  })
  newTodo.value = { title: '', priority: '', dueDate: '', description: '' }
}

function removeTodo(idx) {
  todos.value.splice(idx, 1)
}

async function rewriteAsPirate(idx) {
  loadingIdx.value = idx
  const todo = todos.value[idx]
  try {
    // Use the environment variable for the Azure Function URL
    const functionUrl = import.meta.env.VITE_AZURE_FUNCTION_URL || 'http://localhost:7071/api/RewritePirate'
    const response = await fetch(functionUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ task: todo.description, model: fixedModel })
    })
    if (!response.ok) {
      const errorText = await response.text();
      console.error('API Error:', response.status, errorText);
      throw new Error(`API error: ${response.status} ${errorText.slice(0, 100)}`);
    }
    const pirateText = await response.text()
    todos.value[idx].description = pirateText
  } catch (e) {
    console.error('Error rewriting as pirate:', e);
    alert(`Failed to rewrite as pirate: ${e.message || 'Unknown error'}`);
  } finally {
    loadingIdx.value = null
  }
}
</script>

<style scoped>
.todo-app {
  max-width: 1000px;
  margin: 2rem auto;
  padding: 2rem;
  background: #fff;
  border-radius: 10px;
  box-shadow: 0 6px 24px rgba(0,0,0,0.08);
}

.layout-row {
  display: flex;
  gap: 2rem;
  align-items: flex-start;
}

.panel {
  background: #fbfbfb;
  padding: 1rem;
  border-radius: 8px;
  box-shadow: 0 1px 6px rgba(0,0,0,0.03);
}

.form-panel {
  flex: 1 1 45%;
}

.list-panel {
  flex: 1 1 55%;
  max-height: 70vh;
  overflow: auto;
}

form {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.field {
  display: flex;
  flex-direction: column;
}

.field-label {
  font-size: 0.85rem;
  color: #666;
  margin-bottom: 0.25rem;
}

input, select, textarea {
  padding: 0.6rem;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
}

.actions {
  margin-top: 0.5rem;
}

button {
  padding: 0.6rem 1rem;
  background: #42b983;
  color: #fff;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

button:hover {
  background: #369870;
}

.todo-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.todo-list li {
  padding: 1rem;
  border-radius: 8px;
  background: #ffffff;
  box-shadow: 0 2px 8px rgba(0,0,0,0.04);
  display: flex;
  flex-direction: column;
}

.todo-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  margin-bottom: 0.5rem;
}

.title-block {
  display: flex;
  gap: 0.75rem;
  align-items: center;
}

.title { font-size: 1.05rem }

.controls {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.priority { font-weight: 700; color: #2d6a4f }

.priority-low { border-left: 6px solid #42b983; padding-left: 0.75rem }
.priority-medium { border-left: 6px solid #f7b731; padding-left: 0.75rem }
.priority-high { border-left: 6px solid #eb2f06; padding-left: 0.75rem }

.due-date { font-size: 0.9em; color: #666 }

.description { color: #333; margin-top: 0.25rem }

/* Responsive: stack panels on small screens */
@media (max-width: 800px) {
  .layout-row { flex-direction: column }
  .form-panel, .list-panel { flex: 1 1 100% }
  .todo-app { padding: 1rem }
}

</style>
