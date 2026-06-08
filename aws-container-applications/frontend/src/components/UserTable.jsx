export default function UserTable({ users, onEdit, onDelete }) {
  if (users.length === 0) {
    return <p className="empty">No users yet. Create one above.</p>
  }

  return (
    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>First name</th>
          <th>Last name</th>
          <th>Email</th>
          <th />
        </tr>
      </thead>
      <tbody>
        {users.map((u) => (
          <tr key={u.id}>
            <td>{u.id}</td>
            <td>{u.firstName}</td>
            <td>{u.lastName}</td>
            <td>{u.email}</td>
            <td>
              <div className="actions">
                <button className="secondary" onClick={() => onEdit(u)}>
                  Edit
                </button>
                <button className="danger" onClick={() => onDelete(u)}>
                  Delete
                </button>
              </div>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}
