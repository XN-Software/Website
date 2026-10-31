// The video player: each "Watch the video" button is a link to the video,
// opened here in a dialog instead when scripts run. The video loads only
// once asked for, from YouTube's privacy-enhanced domain.

const player = document.querySelector(".player");
const frame = player.querySelector(".frame");
const title = player.querySelector(".player-title");
let opener = null;

function openVideo(link) {
  const id = link.dataset.video;
  const start = link.dataset.start ? `&start=${encodeURIComponent(link.dataset.start)}` : "";
  const iframe = document.createElement("iframe");
  iframe.src = `https://www.youtube-nocookie.com/embed/${encodeURIComponent(id)}?autoplay=1&rel=0&modestbranding=1${start}`;
  iframe.title = `${link.dataset.title} video`;
  iframe.allow = "autoplay; encrypted-media; picture-in-picture; fullscreen";
  iframe.allowFullscreen = true;
  frame.replaceChildren(iframe);
  title.textContent = link.dataset.title;
  player.classList.toggle("tall", link.dataset.shape === "tall");
  opener = link;
  player.showModal();
}

function closeVideo() {
  if (player.open) player.close();
}

// Closing stops the video, and puts focus back where it came from.
player.addEventListener("close", () => {
  frame.replaceChildren();
  if (opener) opener.focus();
  opener = null;
});

document.querySelectorAll("[data-video]").forEach((link) => {
  link.addEventListener("click", (event) => {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.button > 0) return;
    if (typeof player.showModal !== "function") return;
    event.preventDefault();
    openVideo(link);
  });
});

player.querySelector(".close").addEventListener("click", closeVideo);

// A click on the backdrop, outside the player itself, closes it.
player.addEventListener("click", (event) => {
  const box = player.getBoundingClientRect();
  const inside = event.clientX >= box.left && event.clientX <= box.right
    && event.clientY >= box.top && event.clientY <= box.bottom;
  if (!inside) closeVideo();
});
