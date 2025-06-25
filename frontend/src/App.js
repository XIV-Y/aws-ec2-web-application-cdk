import { useState, useEffect } from 'react';

function App() {
  const [apiData, setApiData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchApiData();
  }, []);

  const fetchApiData = async () => {
    try {
      const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';
      const response = await fetch(`${API_BASE_URL}/api/data`);
      
      if (!response.ok) {
        throw new Error(`API request failed: ${response.status}`);
      }
      
      const data = await response.json();
      setApiData(data);
    } catch (err) {
      console.error('API Error:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <header>
        <h1>Hello World</h1>
        
        <div>
          <h2>API データ</h2>
          {loading && <p>データを読み込み中...</p>}
          {error && <p style={{color: 'red'}}>エラー: {error}</p>}
          {apiData && (
            <div>
              <p><strong>メッセージ:</strong> {apiData.message}</p>
              <p><strong>タイムスタンプ:</strong> {apiData.timestamp}</p>
              <p><strong>ランダム値:</strong> {apiData.randomValue}</p>
            </div>
          )}
          <button onClick={fetchApiData} disabled={loading}>
            データを再取得
          </button>
        </div>
      </header>
    </div>
  );
}

export default App;
