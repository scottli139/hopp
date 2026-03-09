import { FC } from 'react';
import { invoke } from "@tauri-apps/api/core";

const App: FC = () => {
  const greet = async (): Promise<void> => {
    const response = await invoke<string>("greet", { name: "Hopp" });
    console.log(response);
  };

  return (
    <main className="container">
      <h1>Welcome to Hopp 🐰</h1>
      <p>Lightweight API testing tool built with Tauri + React</p>
      <button onClick={greet}>Test Tauri</button>
    </main>
  );
};

export default App;
