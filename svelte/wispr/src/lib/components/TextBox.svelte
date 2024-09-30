<script lang="ts">
	import { Label } from "$lib/components/ui/label/index.js";
	import { Textarea } from "$lib/components/ui/textarea/index.js";
</script>

<div class="border-2 m-1 p-1 grid w-3/4 aspect-square gap-1.5">
	<Label class="h-[20px]" for="message">Your message</Label>
	<Textarea
		class="border-0 aspect-square resize-none"
		placeholder="Type your message here."
		id="message"
	/>
</div>
