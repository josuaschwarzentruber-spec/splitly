import { useState } from 'react';
import { LangProvider } from './hooks/useLang';
import BottomNav from './components/BottomNav';
import Home from './pages/Home';
import Splithead from './pages/Splithead';
import BillSplit from './pages/BillSplit';
import Pro from './pages/Pro';
import './index.css';

const PAGES = { home: Home, split: Splithead, bill: BillSplit, pro: Pro };

export default function App() {
  const [page, setPage] = useState('home');
  const Page = PAGES[page] || Home;

  return (
    <LangProvider>
      <div className="app-shell">
        <Page onNav={setPage} />
        <BottomNav active={page} onNav={setPage} />
      </div>
    </LangProvider>
  );
}
