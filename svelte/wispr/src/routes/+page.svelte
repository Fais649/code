<script lang="ts">
  import { invoke } from "@tauri-apps/api/core";
  import "../app.css";
  import DatePicker from "$lib/components/DatePicker.svelte";

  let name = "";
  let greetMsg = "";

  async function greet() {
    // Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
    greetMsg = await invoke("greet", { name });
  }
</script>

<div class="dark bg-black container">
  <div class="flex flex-col w-full h-full">
    <div class="flex w-full items-center justify-center">
      <div class="p-5 justify-center">
        <DatePicker />
      </div>
    </div>
    <div class="flex flex-col w-full justify-center items-center">
      <textarea
        class="h-80 dark bg-black aspect-square m-3 resize-none border-white border-2"
      ></textarea>
      <textarea
        class="h-80 dark bg-black aspect-square m-3 resize-none border-white border-2"
      ></textarea>
    </div>
  </div>
</div>

<style>
  :root {
    padding: 0px;
  }
</style>
