<template>
  <div class="todo-app">
    <h1>Todo App</h1>
    <form @submit.prevent="addTodo">
      <input v-model="newTodo.title" placeholder="Title" required />
      <select v-model="newTodo.priority" required>
        <option disabled value="">Priority</option>
        <option>Low</option>
        <option>Medium</option>
        <option>High</option>
      </select>
      <input type="date" v-model="newTodo.dueDate" required />
      <textarea v-model="newTodo.description" placeholder="Description" required></textarea>
      <button type="submit">Add Todo</button>
    </form>
    <ul class="todo-list">
      <li v-for="(todo, idx) in todos" :key="todo.id" :class="['priority-' + todo.priority.toLowerCase()]">
        <div class="todo-header">
          <strong>{{ todo.title }}</strong>
          <span class="priority">[{{ todo.priority }}]</span>
          <span class="due-date">Due: {{ todo.dueDate }}</span>
          <button @click="removeTodo(idx)">Delete</button>
          <button @click="rewriteAsPirate(idx)" :disabled="loadingIdx === idx">{{ loadingIdx === idx ? 'Rewriting...' : 'Rewrite as Pirate' }}</button>
        </div>
        <div class="description">{{ todo.description }}</div>
      </li>
    </ul>
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
  max-width: 500px;
  margin: 2rem auto;
  padding: 2rem;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
form {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-bottom: 2rem;
}
input, select, textarea {
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
}
button {
  padding: 0.5rem 1rem;
  background: #42b983;
  color: #fff;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
button:hover {
  background: #369870;
}
.todo-list {
  list-style: none;
  padding: 0;
}
.todo-list li {
  margin-bottom: 1rem;
  padding: 1rem;
  border-radius: 6px;
  background: #f9f9f9;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
}
.todo-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 0.5rem;
}
.priority {
  font-weight: bold;
}
.priority-low {
  border-left: 4px solid #42b983;
}
.priority-medium {
  border-left: 4px solid #f7b731;
}
.priority-high {
  border-left: 4px solid #eb2f06;
}
.due-date {
  margin-left: auto;
  font-size: 0.9em;
  color: #888;
}
.description {
  margin-left: 0.5rem;
  color: #333;
}
</style>
