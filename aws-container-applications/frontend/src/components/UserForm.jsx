import { useEffect, useState } from 'react'

const EMPTY = { firstName: '', lastName: '', email: '' }

export default function UserForm({ editing, onSubmit, onCancel }) {
  const [form, setForm] = useState(EMPTY)

  useEffect(() => {
    if (editing) {
      setForm({ firstName: editing.firstName, lastName: editing.lastName, email: editing.email })
    } else {
      setForm(EMPTY)
    }
  }, [editing])

  const change = (e) => setForm({ ...form, [e.target.name]: e.target.value })

  const submit = (e) => {
    e.preventDefault()
    onSubmit(form)
    if (!editing) setForm(EMPTY)
  }

  return (
    <form className="card" onSubmit={submit}>
      <h2 style={{ fontSize: '1rem', marginTop: 0 }}>
        {editing ? `Edit user #${editing.id}` : 'Create user'}
      </h2>
      <div className="form-row">
        <div className="field">
          <label htmlFor="firstName">First name</label>
          <input id="firstName" name="firstName" value={form.firstName} onChange={change} required />
        </div>
        <div className="field">
          <label htmlFor="lastName">Last name</label>
          <input id="lastName" name="lastName" value={form.lastName} onChange={change} required />
        </div>
        <div className="field">
          <label htmlFor="email">Email</label>
          <input id="email" name="email" type="email" value={form.email} onChange={change} required />
        </div>
        <button type="submit">{editing ? 'Save' : 'Add'}</button>
        {editing && (
          <button type="button" className="secondary" onClick={onCancel}>
            Cancel
          </button>
        )}
      </div>
    </form>
  )
}
