const MOBILE_USER_AGENT = /iPad|iPhone|iPod|android|webOS/i;

function handleDownload(content, filename, type = "text/plain") {
  const blob = new Blob([content], { type: type });

  if (isMobileDevice()) {
    downloadMobile(blob, filename);
  } else {
    downloadDesktop(blob, filename);
  }
}

function isMobileDevice() {
  return MOBILE_USER_AGENT.test(navigator.userAgent);
}

function downloadMobile(blob, filename) {
  const link = document.createElement("a");
  const reader = new FileReader();

  reader.onload = (e) => {
    link.href = e.target.result;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  reader.readAsDataURL(blob);
}

function downloadDesktop(blob, filename) {
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = filename;
  link.click();
  URL.revokeObjectURL(link.href);
}

export { handleDownload };
