import { Route, Routes } from 'react-router-dom'
import { RequireAuth } from './auth/RequireAuth'
import { AppShell } from './components/AppShell'
import { HomePage } from './pages/HomePage'
import { LawsuitPage } from './pages/LawsuitPage'
import { LoginPage } from './pages/LoginPage'
import { NotFoundPage } from './pages/NotFoundPage'
import { SignUpPage } from './pages/SignUpPage'

function App() {
  return (
    <Routes>
      <Route element={<AppShell />}>
        <Route path="login" element={<LoginPage />} />
        <Route path="cadastro" element={<SignUpPage />} />
        <Route element={<RequireAuth />}>
          <Route index element={<HomePage />} />
          <Route path="processos/:number" element={<LawsuitPage />} />
        </Route>
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  )
}

export default App
