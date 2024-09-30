<script lang="ts">
  import { invoke } from "@tauri-apps/api/core";
  import "../app.css";
  import DatePicker from "$lib/components/DatePicker.svelte";
  import MenuBar from "$lib/components/MenuBar.svelte";
  import TextBox from "$lib/components/TextBox.svelte";

  import { getCurrentWindow } from "@tauri-apps/api/window";
  getCurrentWindow().startDragging();
  let name = "";
  let greetMsg = "";

  async function greet() {
    // Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
    greetMsg = await invoke("greet", { name });
  }
</script>

<div class="dark container">
  <div class="flex flex-col w-full h-full">
    <div class="flex w-full items-center justify-center">
      <div class="p-5 justify-center">
        <MenuBar />
        <DatePicker />
      </div>
    </div>
    <div class="flex flex-col w-full justify-center items-center">
      <TextBox />
      <TextBox />
    </div>
  </div>
</div>

<style>
  :root {
    padding: 0px;
  }
</style>
