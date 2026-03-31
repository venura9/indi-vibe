import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import SmartLinkPage from './SmartLinkPage'
import './index.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/:slug" element={<SmartLinkPage />} />
        <Route path="/" element={<SmartLinkPage />} />
      </Routes>
    </BrowserRouter>
  </StrictMode>,
)
