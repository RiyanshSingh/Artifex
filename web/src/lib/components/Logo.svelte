<script lang="ts">
  // The mark: an A drawn as a copper trace with its pads, the one shape a board and a printed part share.
  let { size = 24 }: { size?: number } = $props();
</script>

<svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden="true">
  <path d="M5 20L12 4l7 16M7.6 14h8.8" stroke="var(--primary)" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" />
  <circle cx="12" cy="4" r="2.6" fill="var(--primary)" />
  <circle cx="5" cy="20" r="2.6" fill="var(--primary)" />
  <circle cx="19" cy="20" r="2.6" fill="var(--primary)" />
  <circle cx="12" cy="4" r="0.9" fill="var(--surface)" />
  <circle cx="5" cy="20" r="0.9" fill="var(--surface)" />
  <circle cx="19" cy="20" r="0.9" fill="var(--surface)" />
</svg>
