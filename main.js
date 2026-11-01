// The hero's line, typed: "Software to help you" waits, and a cursor
// types "build beyond" in. The words are in the page from the start, for
// readers, search and anyone without scripts; the typing only draws them.
// The space they take is kept while they type, so nothing below moves.

(function typeHero() {
  const em = document.querySelector("#hero-title em");
  if (!em || matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  const words = em.textContent;
  const title = document.getElementById("hero-title");
  title.setAttribute("aria-label", title.textContent.replace(/\s+/g, " ").trim());
  // The full stop after the words comes with them, typed last, rather
  // than waiting at the far end of their space.
  const after = em.nextSibling;
  const stop = after && after.nodeType === Node.TEXT_NODE && after.data.startsWith(".") ? "." : "";
  if (stop) after.data = after.data.slice(1);
  em.classList.add("typing");
  em.textContent = "";
  const ghost = em.appendChild(document.createElement("span"));
  ghost.className = "ghost";
  ghost.textContent = words + stop;
  const typed = em.appendChild(document.createElement("span"));
  typed.className = "typed";
  typed.setAttribute("aria-hidden", "true");
  const text = typed.appendChild(document.createElement("span"));
  const end = typed.appendChild(document.createElement("span"));
  end.className = "stop";
  const caret = typed.appendChild(document.createElement("span"));
  caret.className = "caret";

  let at = 0;
  const next = () => {
    at += 1;
    text.textContent = words.slice(0, at);
    if (at < words.length) {
      // A person's rhythm: a little uneven, a beat longer at the space.
      setTimeout(next, (words[at - 1] === " " ? 150 : 70) + Math.random() * 60);
    } else {
      setTimeout(() => { end.textContent = stop; }, 160);
      setTimeout(() => caret.classList.add("done"), 1800);
    }
  };
  setTimeout(next, 900);
})();

// The video player: each "Watch the video" button is a link to the video,
// opened here in a dialog instead when scripts run. The video loads only
// once asked for, from YouTube's privacy-enhanced domain.

const player = document.querySelector(".player");
const frame = player.querySelector(".frame");
const title = player.querySelector(".player-title");
const youtube = player.querySelector(".on-youtube");
let opener = null;

function openVideo(link) {
  const id = link.dataset.video;
  const start = link.dataset.start ? `&start=${encodeURIComponent(link.dataset.start)}` : "";
  const iframe = document.createElement("iframe");
  const origin = location.origin.startsWith("http") ? `&origin=${encodeURIComponent(location.origin)}` : "";
  iframe.src = `https://www.youtube-nocookie.com/embed/${encodeURIComponent(id)}?autoplay=1&rel=0&playsinline=1${origin}${start}`;
  iframe.title = `${link.dataset.title} video`;
  iframe.allow = "autoplay; encrypted-media; picture-in-picture; fullscreen";
  // YouTube refuses to play an embed it cannot see the page of ("video
  // player configuration error"), so the page's own address goes with it
  // whatever the host's referrer policy.
  iframe.referrerPolicy = "strict-origin-when-cross-origin";
  iframe.allowFullscreen = true;
  frame.replaceChildren(iframe);
  title.textContent = link.dataset.title;
  youtube.href = link.href;
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
    // Opened from a file, there is no page address to give YouTube, and
    // the embed would only show an error: go to YouTube instead.
    if (!location.protocol.startsWith("http")) return;
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
