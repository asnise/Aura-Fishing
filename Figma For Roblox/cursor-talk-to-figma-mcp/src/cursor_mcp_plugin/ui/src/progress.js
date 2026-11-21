import { progressBar, progressContainer, progressMessage, progressPercentage, progressStatus } from "./dom.js";

const STATUS_TEXT = {
  started: ["Started", ""],
  in_progress: ["In Progress", ""],
  completed: ["Completed", "operation-complete"],
  error: ["Error", "operation-error"],
};

export function updateProgressUI(progressData) {
  progressContainer.classList.remove("hidden");

  const progress = progressData.progress || 0;
  progressBar.style.width = `${progress}%`;
  progressPercentage.textContent = `${progress}%`;
  progressMessage.textContent = progressData.message || "Operation in progress";

  const entry = STATUS_TEXT[progressData.status];
  if (entry) {
    progressStatus.textContent = entry[0];
    progressStatus.className = entry[1];
  }
  if (progressData.status === "completed") {
    setTimeout(() => progressContainer.classList.add("hidden"), 5000);
  }
}

export function resetProgressUI() {
  progressContainer.classList.add("hidden");
  progressBar.style.width = "0%";
  progressMessage.textContent = "No operation in progress";
  progressStatus.textContent = "Not started";
  progressStatus.className = "";
  progressPercentage.textContent = "0%";
}
