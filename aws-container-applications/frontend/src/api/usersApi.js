import axios from 'axios'

// Relative '/api' works everywhere: the Vite dev server proxies it, nginx
// proxies it in docker-compose, and the ALB / Ingress routes it in the cloud.
const baseURL = import.meta.env.VITE_API_BASE_URL ?? '/api'

const client = axios.create({ baseURL })

export const listUsers = () => client.get('/users').then((r) => r.data)
export const createUser = (user) => client.post('/users', user).then((r) => r.data)
export const updateUser = (id, user) => client.put(`/users/${id}`, user).then((r) => r.data)
export const deleteUser = (id) => client.delete(`/users/${id}`)
