/**
 * EduVault - Main Single-Hub Academic Drive Controller
 * Infinite nested folder navigation, file uploads, viewer, and GitHub synchronization.
 */

document.addEventListener('DOMContentLoaded', () => {
  const api = new GitHubAPI();
  const storage = new StorageManager();

  // State
  let config = storage.getConfig();
  let currentPath = '';
  let currentItems = [];
  let currentEditingFile = null;

  // System source files to automatically hide from root view
  const SYSTEM_SOURCE_FILES = [
    'index.html',
    'styles.css',
    'readme.md',
    'js',
    'data',
    '.gitkeep',
    '.gitignore',
    'cname',
    'license',
    'package.json'
  ];

  // DOM Elements
  const globalSearchInput = document.getElementById('global-search-input');
  const headerRepoText = document.getElementById('header-repo-text');
  const btnRefresh = document.getElementById('btn-refresh');
  const btnOpenSettings = document.getElementById('btn-open-settings');

  const bcRoot = document.getElementById('bc-root');
  const bcTrail = document.getElementById('bc-trail');
  const btnViewGrid = document.getElementById('btn-view-grid');
  const btnViewList = document.getElementById('btn-view-list');
  const btnNewStudyFolder = document.getElementById('btn-new-study-folder');
  const btnTriggerUpload = document.getElementById('btn-trigger-upload');
  const btnBrowseClick = document.getElementById('btn-browse-click');
  const hiddenFileInput = document.getElementById('hidden-file-input');
  const studyDropzone = document.getElementById('study-dropzone');
  const uploadProgressBox = document.getElementById('upload-progress-box');
  const upFilename = document.getElementById('up-filename');
  const upPercentage = document.getElementById('up-percentage');
  const upFill = document.getElementById('up-fill');
  const studyFileGrid = document.getElementById('study-file-grid');
  const studyEmpty = document.getElementById('study-empty');
  const studyLoading = document.getElementById('study-loading');
  const btnEmptyCreateFolder = document.getElementById('btn-empty-create-folder');
  const btnEmptyUploadAction = document.getElementById('btn-empty-upload-action');

  // Modals
  const modalSettings = document.getElementById('modal-settings');
  const btnCloseSettings = document.getElementById('btn-close-settings');
  const cfgOwner = document.getElementById('cfg-owner');
  const cfgRepo = document.getElementById('cfg-repo');
  const cfgBranch = document.getElementById('cfg-branch');
  const cfgToken = document.getElementById('cfg-token');
  const btnToggleCfgToken = document.getElementById('btn-toggle-cfg-token');
  const btnTestCfg = document.getElementById('btn-test-cfg');
  const btnSaveCfg = document.getElementById('btn-save-cfg');
  const cfgFeedback = document.getElementById('cfg-feedback');

  const modalViewer = document.getElementById('modal-viewer');
  const btnCloseViewer = document.getElementById('btn-close-viewer');
  const viewerFileName = document.getElementById('viewer-file-name');
  const viewerFileIcon = document.getElementById('viewer-file-icon');
  const viewerBodyContent = document.getElementById('viewer-body-content');
  const viewerFoot = document.getElementById('viewer-foot');
  const btnViewerCopyCdn = document.getElementById('btn-viewer-copy-cdn');
  const btnViewerDownload = document.getElementById('btn-viewer-download');
  const btnViewerDelete = document.getElementById('btn-viewer-delete');
  const btnViewerSaveChanges = document.getElementById('btn-viewer-save-changes');

  const modalFolder = document.getElementById('modal-folder');
  const btnCloseFolder = document.getElementById('btn-close-folder');
  const btnCancelFolder = document.getElementById('btn-cancel-folder');
  const inputNewFolderName = document.getElementById('input-new-folder-name');
  const btnConfirmFolder = document.getElementById('btn-confirm-folder');
  const folderCreateLabel = document.getElementById('folder-create-label');

  const toastHub = document.getElementById('toast-hub');

  // ==========================================================================
  // Toast Notification Helper
  // ==========================================================================
  function showToast(message, type = 'info', duration = 3000) {
    const toast = document.createElement('div');
    toast.className = `toast-msg ${type}`;
    let icon = 'fa-solid fa-circle-info';
    if (type === 'success') icon = 'fa-solid fa-circle-check';
    if (type === 'error') icon = 'fa-solid fa-triangle-exclamation';

    toast.innerHTML = `<i class="${icon}"></i> <span>${message}</span>`;
    toastHub.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(10px)';
      toast.style.transition = 'all 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, duration);
  }

  // ==========================================================================
  // Directory & File Loading (Recursive Tree)
  // ==========================================================================
  async function loadDirectory(path = '') {
    currentPath = path;
    updateBreadcrumbs();
    studyFileGrid.innerHTML = '';
    studyEmpty.style.display = 'none';
    studyLoading.style.display = 'flex';

    try {
      const items = await api.getContents(config.owner, config.repo, currentPath, config.branch, config.token);
      currentItems = items || [];
      applyFilters();
    } catch (e) {
      showToast(`Không thể tải dữ liệu: ${e.message}`, 'error', 4000);
      studyEmpty.style.display = 'flex';
      studyEmpty.querySelector('h3').textContent = 'Lỗi kết nối Repository';
      studyEmpty.querySelector('p').textContent = e.message;
    } finally {
      studyLoading.style.display = 'none';
    }
  }

  function applyFilters() {
    let filtered = [...currentItems];

    // Auto-hide system files at root directory
    if (!currentPath) {
      filtered = filtered.filter(item => !SYSTEM_SOURCE_FILES.includes(item.name.toLowerCase()));
    } else {
      // In sub-folders, only hide .gitkeep
      filtered = filtered.filter(item => item.name !== '.gitkeep');
    }

    // Search query filter
    const query = globalSearchInput.value.toLowerCase().trim();
    if (query) {
      filtered = filtered.filter(item => item.name.toLowerCase().includes(query));
    }

    renderStudyFiles(filtered);
  }

  function renderStudyFiles(items) {
    studyFileGrid.innerHTML = '';

    if (!items || items.length === 0) {
      studyEmpty.style.display = 'flex';
      return;
    }

    studyEmpty.style.display = 'none';

    // Sort folders first, then files alphabetically
    const sorted = [...items].sort((a, b) => {
      if (a.type === b.type) return a.name.localeCompare(b.name);
      return a.type === 'dir' ? -1 : 1;
    });

    sorted.forEach(item => {
      const card = document.createElement('div');
      card.className = `study-card ${item.type === 'dir' ? 'folder' : ''}`;

      if (item.type === 'dir') {
        card.innerHTML = `
          <div class="card-top">
            <div class="card-icon-box" style="background: rgba(251, 191, 36, 0.15); color: var(--amber);">
              <i class="fa-solid fa-folder"></i>
            </div>
            <span class="badge-study-type type-folder">Thư mục</span>
          </div>
          <div class="card-filename" title="${item.name}">${item.name}</div>
          <div class="card-meta-row">
            <span>Bấm để mở thư mục</span>
            <i class="fa-solid fa-chevron-right"></i>
          </div>
        `;
        card.addEventListener('click', () => loadDirectory(item.path));
      } else {
        const fileInfo = storage.classifyStudyFile(item.name);
        const sizeStr = storage.formatBytes(item.size);
        const cdnUrls = api.getPublicUrls(config.owner, config.repo, item.path, config.branch);

        card.innerHTML = `
          <div class="card-top">
            <div class="card-icon-box ${fileInfo.cssClass}">
              <i class="${fileInfo.icon}"></i>
            </div>
            <span class="badge-study-type ${fileInfo.cssClass}">${fileInfo.label}</span>
          </div>
          <div class="card-filename" title="${item.name}">${item.name}</div>
          <div class="card-meta-row">
            <span>${sizeStr}</span>
          </div>
          <div class="card-actions-quick">
            <button class="q-btn btn-copy-cdn-quick" title="Sao chép link CDN" data-url="${cdnUrls.jsdelivr}">
              <i class="fa-solid fa-bolt"></i>
            </button>
            <button class="q-btn btn-view-quick" title="Xem chi tiết">
              <i class="fa-regular fa-eye"></i>
            </button>
          </div>
        `;

        card.querySelector('.btn-copy-cdn-quick').addEventListener('click', (e) => {
          e.stopPropagation();
          navigator.clipboard.writeText(cdnUrls.jsdelivr);
          showToast(`Đã sao chép link tải CDN: ${item.name}`, 'success');
        });

        card.addEventListener('click', () => openViewerModal(item));
      }

      studyFileGrid.appendChild(card);
    });
  }

  // ==========================================================================
  // Breadcrumb Navigation (Gốc > Cấp 1 > Cấp 2...)
  // ==========================================================================
  function updateBreadcrumbs() {
    bcTrail.innerHTML = '';
    if (!currentPath) {
      bcRoot.classList.add('active');
      return;
    }
    bcRoot.classList.remove('active');

    const parts = currentPath.split('/').filter(Boolean);
    let accum = '';

    parts.forEach((p, idx) => {
      accum += (idx === 0 ? '' : '/') + p;
      const target = accum;

      const sep = document.createElement('span');
      sep.className = 'bc-sep';
      sep.innerHTML = '<i class="fa-solid fa-chevron-right"></i>';
      bcTrail.appendChild(sep);

      const btn = document.createElement('button');
      btn.className = `bc-item ${idx === parts.length - 1 ? 'active' : ''}`;
      btn.innerHTML = `<i class="fa-regular fa-folder-open text-amber"></i> <span>${p}</span>`;
      btn.addEventListener('click', () => loadDirectory(target));
      bcTrail.appendChild(btn);
    });
  }

  bcRoot.addEventListener('click', () => loadDirectory(''));
  globalSearchInput.addEventListener('input', applyFilters);

  // View switch (Grid / List)
  btnViewGrid.addEventListener('click', () => {
    btnViewGrid.classList.add('active');
    btnViewList.classList.remove('active');
    studyFileGrid.classList.remove('list-view');
  });

  btnViewList.addEventListener('click', () => {
    btnViewList.classList.add('active');
    btnViewGrid.classList.remove('active');
    studyFileGrid.classList.add('list-view');
  });

  // ==========================================================================
  // Drag & Drop / File Uploading in Current Directory
  // ==========================================================================
  ['dragenter', 'dragover'].forEach(eName => {
    studyDropzone.addEventListener(eName, (e) => {
      e.preventDefault();
      studyDropzone.classList.add('dragover');
    });
  });

  ['dragleave', 'drop'].forEach(eName => {
    studyDropzone.addEventListener(eName, (e) => {
      e.preventDefault();
      studyDropzone.classList.remove('dragover');
    });
  });

  studyDropzone.addEventListener('drop', (e) => {
    const files = e.dataTransfer.files;
    if (files.length > 0) uploadFiles(Array.from(files));
  });

  btnTriggerUpload.addEventListener('click', () => hiddenFileInput.click());
  btnBrowseClick.addEventListener('click', () => hiddenFileInput.click());
  btnEmptyUploadAction.addEventListener('click', () => hiddenFileInput.click());

  hiddenFileInput.addEventListener('change', (e) => {
    if (e.target.files.length > 0) {
      uploadFiles(Array.from(e.target.files));
      hiddenFileInput.value = '';
    }
  });

  async function uploadFiles(files) {
    if (!config.token) {
      showToast('Cần có GitHub Token (PAT) trong Cấu Hình để tải tài liệu lên!', 'error', 4000);
      modalSettings.style.display = 'flex';
      return;
    }

    uploadProgressBox.style.display = 'block';
    const total = files.length;
    let done = 0;

    for (let i = 0; i < total; i++) {
      const file = files[i];
      const targetPath = currentPath ? `${currentPath}/${file.name}` : file.name;
      upFilename.textContent = `Đang tải (${i + 1}/${total}): ${file.name}`;
      const pct = Math.round(((i) / total) * 100);
      upFill.style.width = `${pct}%`;
      upPercentage.textContent = `${pct}%`;

      try {
        const b64 = await storage.fileToBase64(file);
        const existing = currentItems.find(it => it.name === file.name);
        const sha = existing ? existing.sha : null;

        await api.uploadFile(
          config.owner,
          config.repo,
          targetPath,
          b64,
          `EduVault: Lưu tài liệu ${file.name}`,
          sha,
          config.branch,
          config.token
        );
        done++;
        showToast(`Đã lưu thành công: ${file.name}`, 'success');
      } catch (err) {
        showToast(`Lỗi tải lên ${file.name}: ${err.message}`, 'error');
      }
    }

    upFill.style.width = '100%';
    upPercentage.textContent = '100%';
    setTimeout(() => {
      uploadProgressBox.style.display = 'none';
      upFill.style.width = '0%';
    }, 1200);

    loadDirectory(currentPath);
  }

  // ==========================================================================
  // Create Folder (Nested in Current Directory)
  // ==========================================================================
  function openFolderModal() {
    if (!config.token) {
      showToast('Cần có GitHub Token để tạo thư mục.', 'error');
      modalSettings.style.display = 'flex';
      return;
    }
    inputNewFolderName.value = '';
    const currentLoc = currentPath ? `trong thư mục '${currentPath}'` : 'tại Thư mục gốc';
    folderCreateLabel.innerHTML = `Tên thư mục mới (${currentLoc}):`;
    modalFolder.style.display = 'flex';
    inputNewFolderName.focus();
  }

  btnNewStudyFolder.addEventListener('click', openFolderModal);
  btnEmptyCreateFolder.addEventListener('click', openFolderModal);
  btnCloseFolder.addEventListener('click', () => modalFolder.style.display = 'none');
  btnCancelFolder.addEventListener('click', () => modalFolder.style.display = 'none');

  btnConfirmFolder.addEventListener('click', async () => {
    const fName = inputNewFolderName.value.trim().replace(/[\\/:*?"<>|]/g, '');
    if (!fName) {
      showToast('Vui lòng nhập tên thư mục hợp lệ.', 'error');
      return;
    }

    const folderPlaceholder = currentPath ? `${currentPath}/${fName}/.gitkeep` : `${fName}/.gitkeep`;
    try {
      modalFolder.style.display = 'none';
      showToast('Đang tạo thư mục trên GitHub...', 'info');
      await api.uploadFile(
        config.owner,
        config.repo,
        folderPlaceholder,
        storage.utf8ToBase64('# EduVault Folder Placeholder'),
        `EduVault: Tạo thư mục ${fName}`,
        null,
        config.branch,
        config.token
      );
      showToast(`Đã tạo thư mục '${fName}' thành công!`, 'success');
      loadDirectory(currentPath);
    } catch (err) {
      showToast(`Lỗi tạo thư mục: ${err.message}`, 'error');
    }
  });

  // ==========================================================================
  // File Viewer Modal
  // ==========================================================================
  async function openViewerModal(item) {
    viewerFileName.textContent = item.name;
    const info = storage.classifyStudyFile(item.name);
    viewerFileIcon.className = `${info.icon} ${info.cssClass}`;

    const cdnUrls = api.getPublicUrls(config.owner, config.repo, item.path, config.branch);
    btnViewerDownload.href = item.download_url || cdnUrls.raw;
    btnViewerDownload.setAttribute('download', item.name);

    btnViewerCopyCdn.onclick = () => {
      navigator.clipboard.writeText(cdnUrls.jsdelivr);
      showToast('Đã sao chép link CDN jsDelivr!', 'success');
    };

    btnViewerDelete.onclick = async () => {
      if (!config.token) return showToast('Cần có Token để xóa tài liệu.', 'error');
      if (confirm(`Bạn có chắc muốn xóa '${item.name}' khỏi kho dữ liệu?`)) {
        try {
          showToast('Đang xóa tài liệu...', 'info');
          await api.deleteFile(config.owner, config.repo, item.path, item.sha, `EduVault: Xóa ${item.name}`, config.branch, config.token);
          modalViewer.style.display = 'none';
          showToast(`Đã xóa ${item.name}!`, 'success');
          loadDirectory(currentPath);
        } catch (e) {
          showToast(`Lỗi: ${e.message}`, 'error');
        }
      }
    };

    viewerBodyContent.innerHTML = '<div style="text-align:center; padding:3rem;"><i class="fa-solid fa-spinner fa-spin text-mint"></i> Đang tải nội dung...</div>';
    viewerFoot.style.display = 'none';
    modalViewer.style.display = 'flex';

    try {
      const fileData = await api.getFileDetails(config.owner, config.repo, item.path, config.branch, config.token);
      
      if (item.name.toLowerCase().endsWith('.pdf')) {
        viewerBodyContent.innerHTML = `
          <iframe src="https://docs.google.com/viewer?url=${encodeURIComponent(cdnUrls.raw)}&embedded=true" style="width:100%; height:100%; min-height:560px; border:none; border-radius:8px;"></iframe>
        `;
      } else if (info.category === 'image') {
        viewerBodyContent.innerHTML = `
          <div style="display:flex; justify-content:center; align-items:center; height:100%;">
            <img src="${cdnUrls.jsdelivr}" alt="${item.name}" style="max-width:100%; max-height:65vh; border-radius:8px; object-fit:contain;">
          </div>
        `;
      } else if (info.category === 'video') {
        viewerBodyContent.innerHTML = `
          <div style="display:flex; justify-content:center; align-items:center; height:100%;">
            <video controls autoplay style="max-width:100%; max-height:60vh; border-radius:8px;">
              <source src="${cdnUrls.raw}">
            </video>
          </div>
        `;
      } else if (['code', 'notes', 'other'].includes(info.category)) {
        const decoded = storage.base64ToUtf8(fileData.content || '');
        currentEditingFile = { name: item.name, path: item.path, sha: fileData.sha };
        viewerBodyContent.innerHTML = `
          <textarea id="viewer-code-editor" class="code-editor-textarea" spellcheck="false">${decoded}</textarea>
        `;
        viewerFoot.style.display = 'flex';
      } else {
        viewerBodyContent.innerHTML = `
          <div class="study-empty">
            <div class="empty-icon-box"><i class="${info.icon}"></i></div>
            <h3>Tệp định dạng ${item.name.split('.').pop().toUpperCase()}</h3>
            <p>Định dạng này phù hợp tải xuống trực tiếp hoặc mở bằng ứng dụng trên máy tính.</p>
          </div>
        `;
      }
    } catch (err) {
      viewerBodyContent.innerHTML = `<div class="study-empty"><p class="text-danger">Lỗi: ${err.message}</p></div>`;
    }
  }

  btnCloseViewer.addEventListener('click', () => {
    modalViewer.style.display = 'none';
    currentEditingFile = null;
  });

  btnViewerSaveChanges.addEventListener('click', async () => {
    if (!config.token || !currentEditingFile) return showToast('Cần có Token để lưu thay đổi.', 'error');
    const editor = document.getElementById('viewer-code-editor');
    const newContent = editor ? editor.value : '';

    try {
      showToast('Đang commit thay đổi lên GitHub...', 'info');
      const res = await api.uploadFile(
        config.owner,
        config.repo,
        currentEditingFile.path,
        storage.utf8ToBase64(newContent),
        `EduVault: Cập nhật ${currentEditingFile.name}`,
        currentEditingFile.sha,
        config.branch,
        config.token
      );
      currentEditingFile.sha = res.content.sha;
      showToast(`Đã lưu thay đổi vào ${currentEditingFile.name}!`, 'success');
      loadDirectory(currentPath);
    } catch (e) {
      showToast(`Lỗi: ${e.message}`, 'error');
    }
  });

  // ==========================================================================
  // Settings & Configuration Modal
  // ==========================================================================
  function openSettings() {
    cfgOwner.value = config.owner;
    cfgRepo.value = config.repo;
    cfgBranch.value = config.branch || 'main';
    cfgToken.value = config.token || '';
    cfgFeedback.style.display = 'none';
    modalSettings.style.display = 'flex';
  }

  btnOpenSettings.addEventListener('click', openSettings);
  btnCloseSettings.addEventListener('click', () => modalSettings.style.display = 'none');

  btnToggleCfgToken.addEventListener('click', () => {
    const isPw = cfgToken.type === 'password';
    cfgToken.type = isPw ? 'text' : 'password';
    btnToggleCfgToken.innerHTML = isPw ? '<i class="fa-regular fa-eye-slash"></i>' : '<i class="fa-regular fa-eye"></i>';
  });

  btnTestCfg.addEventListener('click', async () => {
    const o = cfgOwner.value.trim();
    const r = cfgRepo.value.trim();
    const t = cfgToken.value.trim();

    if (!o || !r) {
      cfgFeedback.className = 'feedback-box error';
      cfgFeedback.style.display = 'block';
      cfgFeedback.textContent = 'Vui lòng nhập Username và Tên Kho lưu trữ.';
      return;
    }

    cfgFeedback.className = 'feedback-box';
    cfgFeedback.style.display = 'block';
    cfgFeedback.textContent = 'Đang kiểm tra kết nối tới GitHub...';

    try {
      const details = await api.getRepoDetails(o, r, t);
      cfgFeedback.className = 'feedback-box success';
      cfgFeedback.innerHTML = `Kết nối thành công tới kho <strong>${details.full_name}</strong>! ${t ? '(Đã có quyền ghi Token)' : '(Chế độ xem công khai)'}`;
    } catch (e) {
      cfgFeedback.className = 'feedback-box error';
      cfgFeedback.textContent = `Lỗi: ${e.message}`;
    }
  });

  btnSaveCfg.addEventListener('click', () => {
    const owner = cfgOwner.value.trim();
    const repo = cfgRepo.value.trim();
    const branch = cfgBranch.value.trim() || 'main';
    const token = cfgToken.value.trim();

    if (!owner || !repo) return showToast('Vui lòng điền đủ thông tin kho.', 'error');

    config = { owner, repo, branch, token };
    storage.saveConfig(config);
    modalSettings.style.display = 'none';

    headerRepoText.textContent = config.repo;
    loadDirectory('');
    showToast('Đã lưu cấu hình và kết nối thành công!', 'success');
  });

  btnRefresh.addEventListener('click', () => {
    loadDirectory(currentPath);
    showToast('Đã làm mới dữ liệu!', 'info');
  });

  // Initial Load
  headerRepoText.textContent = config.repo;
  loadDirectory('');
});
