'use client';

import { useEffect, useState } from 'react';

export default fu(nction Home() {
  const [data, setData] = useState<{ Hello?: string }>({});

  useEffect(() => {
    // FastAPIのURLを指定
    // fetch'http://localhost:8000/')
    fetch('/api/hello')
      .then((res) => res.json())
      .then((data) => setData(data))
      .catch((err) => console.error("Error fetching data:", err));
  }, []);

  return (
    <main style={{ padding: '2rem', textAlign: 'center' }}>
      <h1>Next.js + FastAPI 疎通テスト</h1>
      <div style={{ marginTop: '1rem', padding: '1rem', border: '1px solid #ccc' }}>
        <p>Backendからのレスポンス:</p>
        <h2 style={{ color: '#0070f3' }}>
          {data.Hello ? data.Hello : "読み込み中..."}
        </h2>
      </div>
    </main>
  );
}