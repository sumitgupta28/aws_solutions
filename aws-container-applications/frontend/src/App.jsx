import { useEffect, useState } from 'react'
import { listUsers, createUser, updateUser, deleteUser } from './api/usersApi'
import UserForm from './components/UserForm'
import UserTable from './components/UserTable'

export default function App() {
  const [users, setUsers] = useState([])
  const [editing, setEditing] = useState(null)
  const [error, setError] = useState('')

  const refresh = async () => {
    try {
      setUsers(await listUsers())
      setError('')
    } catch (e) {
      setError(describe(e))
    }
  }

  useEffect(() => {
    refresh()
  }, [])

  const handleSubmit = async (form) => {
    try {
      if (editing) {
        await updateUser(editing.id, form)
        setEditing(null)
      } else {
        await createUser(form)
      }
      await refresh()
    } catch (e) {
      setError(describe(e))
    }
  }

  const handleDelete = async (user) => {
    if (!window.confirm(`Delete ${user.firstName} ${user.lastName}?`)) return
    try {
      await deleteUser(user.id)
      if (editing?.id === user.id) setEditing(null)
      await refresh()
    } catch (e) {
      setError(describe(e))
    }
  }

  return (
    <div className="container">
      <h1>User Management</h1>
      <UserForm editing={editing} onSubmit={handleSubmit} onCancel={() => setEditing(null)} />
      {error && <p className="error">{error}</p>}
      <div className="card">
        <UserTable users={users} onEdit={setEditing} onDelete={handleDelete} />
      </div>
    </div>
  )
}

function describe(e) {
  const data = e.response?.data
  if (data?.fieldErrors) {
    return Object.entries(data.fieldErrors)
      .map(([f, m]) => `${f}: ${m}`)
      .join(', ')
  }
  return data?.message || e.message || 'Request failed'
}
