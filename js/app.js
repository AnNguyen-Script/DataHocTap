/**
 * GitVault - Main Application Controller
 * Wires together GitHub API, Storage Manager, UI Interactions, Modals, Drag & Drop, and Real-time State.
 */

document.addEventListener('DOMContentLoaded', () => {
  // Initialize Services
  const api = new GitHubAPI();
  const storage = new StorageManager();

  // App State
  let config = storage.getConfig();
  let currentPath = '';
  let currentItems = [];
  let currentFileEditing = null; // { name, path, sha, content, isBinary }
  let currentDbPath = 'data/records.json';
  let currentDbRecords = [];
  let currentDbSha = null;
  let viewMode = 'grid'; // 'grid' | 'list'

  // DOM Elements - Navigation & Header
  const navTabs = document.querySelectorAll('.nav-tab');
  const tabPanes = document.querySelectorAll('.tab-pane');
  const repoBadgeName = document.getElementById('repo-badge-name');
  const statusIndicator = document.getElementById('status-indicator');
  const statTotalItems = document.getElementById('stat-total-items');
  const statAuthMode = document.getElementById('stat-auth-mode');
  const statCurrentBranch = document.getElementById('stat-current-branch');
  const btnRefresh = document.getElementById('btn-refresh');
  const btnOpenSettings = document.getElementById('btn-open-settings');

  // DOM Elements - Cloud Drive
  const breadcrumbRoot = document.getElementById('breadcrumb-root');
  const breadcrumbTrail = document.getElementById('breadcrumb-trail');
  const fileSearchInput = document.getElementById('file-search-input');
  const searchClearBtn = document.getElementById('search-clear-btn');
  const viewGridBtn = document.getElementById('view-grid-btn');
  const viewListBtn = document.getElementById('view-list-btn');
  const fileExplorerGrid = document.getElementById('file-explorer-grid');
  const explorerEmptyState = document.getElementById('explorer-empty-state');
  const explorerLoadingState = document.getElementById('explorer-loading-state');
  const uploadDropzone = document.getElementById('upload-dropzone');
  const fileInputHidden = document.getElementById('file-input-hidden');
  const btnBrowseFiles = document.getElementById('btn-browse-files');
  const btnUploadTrigger = document.getElementById('btn-upload-trigger');
  const btnEmptyUpload = document.getElementById('btn-empty-upload');
  const uploadProgressWrapper = document.getElementById('upload-progress-wrapper');
  const uploadProgressBar = document.getElementById('upload-progress-bar');
  const uploadStatusText = document.getElementById('upload-status-text');
  const uploadPercentText = document.getElementById('upload-percent-text');
  const btnNewFolder = document.getElementById('btn-new-folder');
  const btnNewFile = document.getElementById('btn-new-file');

  // DOM Elements - Database Tab
  const dbFileSelect = document.getElementById('db-file-select');
  const btnNewDbTable = document.getElementById('btn-new-db-table');
  const btnAddDbRecord = document.getElementById('btn-add-db-record');
  const btnExportDb = document.getElementById('btn-export-db');
  const dbSearchInput = document.getElementById('db-search-input');
  const dbRecordsTable = document.getElementById('db-records-table');
  const dbTableBody = document.getElementById('db-table-body');
  const dbEmptyState = document.getElementById('db-empty-state');
  const dbRecordCount = document.getElementById('db-record-count');

  // DOM Elements - CDN Generator
  const cdnFilePathInput = document.getElementById('cdn-file-path-input');
  const btnGenerateCdn = document.getElementById('btn-generate-cdn');
  const cdnUrlJsdelivr = document.getElementById('cdn-url-jsdelivr');
  const cdnUrlRaw = document.getElementById('cdn-url-raw');
  const cdnUrlHtmlImg = document.getElementById('cdn-url-html-img');
  const cdnUrlMarkdown = document.getElementById('cdn-url-markdown');

  // DOM Elements - Modals
  const settingsModal = document.getElementById('settings-modal');
  const btnCloseSettings = document.getElementById('btn-close-settings');
  const inputRepoOwner = document.getElementById('input-repo-owner');
  const inputRepoName = document.getElementById('input-repo-name');
  const inputRepoBranch = document.getElementById('input-repo-branch');
  const inputRepoToken = document.getElementById('input-repo-token');
  const btnTogglePat = document.getElementById('btn-toggle-pat');
  const btnTestConnection = document.getElementById('btn-test-connection');
  const btnSaveSettings = document.getElementById('btn-save-settings');
  const connectionFeedback = document.getElementById('connection-feedback');

  const previewModal = document.getElementById('preview-modal');
  const btnClosePreview = document.getElementById('btn-close-preview');
  const previewFileTitle = document.getElementById('preview-file-title');
  const previewFileIcon = document.getElementById('preview-file-icon');
  const previewModalBody = document.getElementById('preview-modal-body');
  const previewModalFooter = document.getElementById('preview-modal-footer');
  const btnSaveFileChanges = document.getElementById('btn-save-file-changes');
  const btnPreviewCopyCdn = document.getElementById('btn-preview-copy-cdn');
  const btnPreviewDownload = document.getElementById('btn-preview-download');
  const btnPreviewDelete = document.getElementById('btn-preview-delete');

  const folderModal = document.getElementById('folder-modal');
  const btnCloseFolderModal = document.getElementById('btn-close-folder-modal');
  const inputFolderName = document.getElementById('input-folder-name');
  const btnCancelFolder = document.getElementById('btn-cancel-folder');
  const btnConfirmCreateFolder = document.getElementById('btn-confirm-create-folder');

  const newFileModal = document.getElementById('new-file-modal');
  const btnCloseNewFileModal = document.getElementById('btn-close-new-file-modal');
  const inputNewFilename = document.getElementById('input-new-filename');
  const inputNewFilecontent = document.getElementById('input-new-filecontent');
  const btnCancelNewFile = document.getElementById('btn-cancel-new-file');
  const btnConfirmCreateFile = document.getElementById('btn-confirm-create-file');

  const recordModal = document.getElementById('record-modal');
  const btnCloseRecordModal = document.getElementById('btn-close-record-modal');
  const recordModalTitle = document.getElementById('record-modal-title');
  const recordEditId = document.getElementById('record-edit-id');
  const recordInputTitle = document.getElementById('record-input-title');
  const recordInputCategory = document.getElementById('record-input-category');
  const recordInputContent = document.getElementById('record-input-content');
  const recordInputTags = document.getElementById('record-input-tags');
  const btnCancelRecord = document.getElementById('btn-cancel-record');
  const btnSaveRecord = document.getElementById('btn-save-record');

  const toastContainer = document.getElementById('toast-container');

  // ==========================================================================
  // Helper: Toast Notifications
  // ==========================================================================
  function showToast(message, type = 'info', duration = 3500) {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;

    let iconClass = 'fa-solid fa-circle-info';
    if (type === 'success') iconClass = 'fa-solid fa-circle-check';
    if (type === 'error') iconClass = 'fa-solid fa-triangle-exclamation';

    toast.innerHTML = `
      <div class="toast-icon"><i class="${iconClass}"></i></div>
      <div class="toast-text">${message}</div>
    `;

    toastContainer.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateX(100%)';
      toast.style.transition = 'all 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, duration);
  }

  // ==========================================================================
  // Tab Navigation Switching
  // ==========================================================================
  navTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      navTabs.forEach(t => t.classList.remove('active'));
      tabPanes.forEach(p => p.classList.remove('active'));

      tab.classList.add('active');
      const targetPane = document.getElementById(tab.dataset.tab);
      if (targetPane) targetPane.classList.add('active');

      if (tab.dataset.tab === 'database-tab') {
        loadDatabaseData();
      }
    });
  });

  // ==========================================================================
  // Update Header & Stats Summary
  // ==========================================================================
  function updateHeaderStats() {
    repoBadgeName.textContent = `${config.owner}/${config.repo}`;
    statCurrentBranch.textContent = config.branch || 'main';

    if (config.token && config.token.trim() !== '') {
      statAuthMode.textContent = 'Quyền Quản Trị (Read & Write)';
      statAuthMode.className = 'stat-value text-success';
      statusIndicator.className = 'status-indicator online';
    } else {
      statAuthMode.textContent = 'Chế độ Công khai (Read-Only)';
      statAuthMode.className = 'stat-value text-cyan';
      statusIndicator.className = 'status-indicator warning';
    }
  }

  // ==========================================================================
  // Cloud Drive: Load Directory Contents
  // ==========================================================================
  async function loadDirectory(path = '') {
    currentPath = path;
    updateBreadcrumbs();
    fileExplorerGrid.innerHTML = '';
    explorerEmptyState.style.display = 'none';
    explorerLoadingState.style.display = 'flex';

    try {
      const items = await api.getContents(config.owner, config.repo, currentPath, config.branch, config.token);
      currentItems = items || [];
      renderFileExplorer(currentItems);
      statTotalItems.textContent = `${currentItems.length} mục`;
    } catch (error) {
      showToast(`Không thể tải dữ liệu: ${error.message}`, 'error', 5000);
      explorerEmptyState.style.display = 'flex';
      explorerEmptyState.querySelector('h3').textContent = 'Lỗi kết nối Repository';
      explorerEmptyState.querySelector('p').textContent = error.message;
    } finally {
      explorerLoadingState.style.display = 'none';
    }
  }

  // ==========================================================================
  // Cloud Drive: Render File Explorer
  // ==========================================================================
  function renderFileExplorer(items) {
    fileExplorerGrid.innerHTML = '';

    if (!items || items.length === 0) {
      explorerEmptyState.style.display = 'flex';
      return;
    }

    explorerEmptyState.style.display = 'none';

    // Sort folders first, then alphabetically
    const sorted = [...items].sort((a, b) => {
      if (a.type === b.type) return a.name.localeCompare(b.name);
      return a.type === 'dir' ? -1 : 1;
    });

    sorted.forEach(item => {
      // Don't hide .gitkeep completely, but style it subtly if needed
      const card = document.createElement('div');
      card.className = `file-card ${item.type === 'dir' ? 'folder' : 'file'}`;
      card.dataset.path = item.path;
      card.dataset.type = item.type;
      card.dataset.name = item.name;
      card.dataset.sha = item.sha;

      if (item.type === 'dir') {
        card.innerHTML = `
          <div class="file-thumbnail">
            <i class="fa-solid fa-folder"></i>
          </div>
          <div class="file-name" title="${item.name}">${item.name}</div>
          <div class="file-meta">Thư mục</div>
          <div class="file-actions-hover">
            <button class="file-quick-btn btn-enter-folder" title="Mở thư mục">
              <i class="fa-solid fa-arrow-right"></i>
            </button>
          </div>
        `;

        card.addEventListener('click', (e) => {
          if (!e.target.closest('.file-actions-hover')) {
            loadDirectory(item.path);
          }
        });
      } else {
        const typeInfo = storage.getFileTypeInfo(item.name);
        const sizeFormatted = storage.formatBytes(item.size);
        const cdnUrls = api.getPublicUrls(config.owner, config.repo, item.path, config.branch);

        let thumbnailHtml = `<i class="${typeInfo.icon} ${typeInfo.color}"></i>`;
        if (typeInfo.type === 'image') {
          thumbnailHtml = `<img src="${cdnUrls.jsdelivr}" alt="${item.name}" loading="lazy" onerror="this.outerHTML='<i class=\\'${typeInfo.icon} ${typeInfo.color}\\'></i>'">`;
        }

        card.innerHTML = `
          <div class="file-thumbnail">
            ${thumbnailHtml}
          </div>
          <div class="file-name" title="${item.name}">${item.name}</div>
          <div class="file-meta">${sizeFormatted}</div>
          <div class="file-actions-hover">
            <button class="file-quick-btn btn-quick-copy" title="Sao chép link CDN" data-cdn="${cdnUrls.jsdelivr}">
              <i class="fa-solid fa-bolt"></i>
            </button>
            <button class="file-quick-btn btn-quick-preview" title="Xem chi tiết">
              <i class="fa-regular fa-eye"></i>
            </button>
          </div>
        `;

        // Quick Copy CDN event
        const quickCopyBtn = card.querySelector('.btn-quick-copy');
        quickCopyBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          navigator.clipboard.writeText(quickCopyBtn.dataset.cdn);
          showToast(`Đã sao chép CDN Link: ${item.name}`, 'success');
        });

        // Open preview modal on card click
        card.addEventListener('click', () => {
          openFilePreview(item);
        });
      }

      fileExplorerGrid.appendChild(card);
    });
  }

  // ==========================================================================
  // Breadcrumb Trail Management
  // ==========================================================================
  function updateBreadcrumbs() {
    breadcrumbTrail.innerHTML = '';

    if (!currentPath) {
      breadcrumbRoot.classList.add('active');
      return;
    }

    breadcrumbRoot.classList.remove('active');
    const segments = currentPath.split('/').filter(Boolean);
    let accumulatedPath = '';

    segments.forEach((seg, idx) => {
      accumulatedPath += (idx === 0 ? '' : '/') + seg;
      const targetPath = accumulatedPath;

      const sep = document.createElement('span');
      sep.className = 'breadcrumb-separator';
      sep.innerHTML = '<i class="fa-solid fa-chevron-right"></i>';
      breadcrumbTrail.appendChild(sep);

      const itemBtn = document.createElement('button');
      itemBtn.className = `breadcrumb-item ${idx === segments.length - 1 ? 'active' : ''}`;
      itemBtn.textContent = seg;
      itemBtn.addEventListener('click', () => loadDirectory(targetPath));

      breadcrumbTrail.appendChild(itemBtn);
    });
  }

  breadcrumbRoot.addEventListener('click', () => loadDirectory(''));

  // ==========================================================================
  // File Search Filter
  // ==========================================================================
  fileSearchInput.addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase().trim();
    searchClearBtn.style.display = query ? 'block' : 'none';

    if (!query) {
      renderFileExplorer(currentItems);
      return;
    }

    const filtered = currentItems.filter(item => item.name.toLowerCase().includes(query));
    renderFileExplorer(filtered);
  });

  searchClearBtn.addEventListener('click', () => {
    fileSearchInput.value = '';
    searchClearBtn.style.display = 'none';
    renderFileExplorer(currentItems);
  });

  // View toggle
  viewGridBtn.addEventListener('click', () => {
    viewGridBtn.classList.add('active');
    viewListBtn.classList.remove('active');
    fileExplorerGrid.classList.remove('list-view');
    viewMode = 'grid';
  });

  viewListBtn.addEventListener('click', () => {
    viewListBtn.classList.add('active');
    viewGridBtn.classList.remove('active');
    fileExplorerGrid.classList.add('list-view');
    viewMode = 'list';
  });

  // ==========================================================================
  // Drag & Drop / File Uploading to GitHub
  // ==========================================================================
  ['dragenter', 'dragover'].forEach(eventName => {
    uploadDropzone.addEventListener(eventName, (e) => {
      e.preventDefault();
      uploadDropzone.classList.add('dragover');
    });
  });

  ['dragleave', 'drop'].forEach(eventName => {
    uploadDropzone.addEventListener(eventName, (e) => {
      e.preventDefault();
      uploadDropzone.classList.remove('dragover');
    });
  });

  uploadDropzone.addEventListener('drop', (e) => {
    const files = e.dataTransfer.files;
    if (files.length > 0) {
      handleFilesUpload(Array.from(files));
    }
  });

  btnBrowseFiles.addEventListener('click', () => fileInputHidden.click());
  btnUploadTrigger.addEventListener('click', () => fileInputHidden.click());
  btnEmptyUpload.addEventListener('click', () => fileInputHidden.click());

  fileInputHidden.addEventListener('change', (e) => {
    if (e.target.files.length > 0) {
      handleFilesUpload(Array.from(e.target.files));
      fileInputHidden.value = '';
    }
  });

  async function handleFilesUpload(filesList) {
    if (!config.token) {
      showToast('Cần có GitHub Token (PAT) để tải lên tệp tin!', 'error', 4000);
      openSettingsModal();
      return;
    }

    uploadProgressWrapper.style.display = 'block';
    const total = filesList.length;
    let completed = 0;

    for (let i = 0; i < total; i++) {
      const file = filesList[i];
      const targetPath = currentPath ? `${currentPath}/${file.name}` : file.name;

      uploadStatusText.textContent = `Đang tải (${i + 1}/${total}): ${file.name}...`;
      const percent = Math.round(((i) / total) * 100);
      uploadProgressBar.style.width = `${percent}%`;
      uploadPercentText.textContent = `${percent}%`;

      try {
        const base64Content = await storage.fileToBase64(file);
        // Check if file already exists in currentItems to get sha for updating
        const existingItem = currentItems.find(item => item.name === file.name);
        const sha = existingItem ? existingItem.sha : null;

        await api.uploadFile(
          config.owner,
          config.repo,
          targetPath,
          base64Content,
          `GitVault: Tải lên ${file.name}`,
          sha,
          config.branch,
          config.token
        );

        completed++;
        showToast(`Đã tải lên thành công: ${file.name}`, 'success');
      } catch (err) {
        showToast(`Lỗi khi tải lên ${file.name}: ${err.message}`, 'error', 5000);
      }
    }

    uploadProgressBar.style.width = '100%';
    uploadPercentText.textContent = '100%';
    uploadStatusText.textContent = `Hoàn thành ${completed}/${total} tệp!`;

    setTimeout(() => {
      uploadProgressWrapper.style.display = 'none';
      uploadProgressBar.style.width = '0%';
    }, 1500);

    // Refresh directory
    loadDirectory(currentPath);
  }

  // ==========================================================================
  // Create New Folder & New File
  // ==========================================================================
  btnNewFolder.addEventListener('click', () => {
    if (!config.token) {
      showToast('Cần có GitHub Token để tạo thư mục.', 'error');
      openSettingsModal();
      return;
    }
    inputFolderName.value = '';
    folderModal.style.display = 'flex';
    inputFolderName.focus();
  });

  btnCloseFolderModal.addEventListener('click', () => folderModal.style.display = 'none');
  btnCancelFolder.addEventListener('click', () => folderModal.style.display = 'none');

  btnConfirmCreateFolder.addEventListener('click', async () => {
    const folderName = inputFolderName.value.trim().replace(/[\\/:*?"<>|]/g, '');
    if (!folderName) {
      showToast('Vui lòng nhập tên thư mục hợp lệ.', 'error');
      return;
    }

    const folderPath = currentPath ? `${currentPath}/${folderName}/.gitkeep` : `${folderName}/.gitkeep`;
    try {
      folderModal.style.display = 'none';
      showToast('Đang tạo thư mục trên GitHub...', 'info');
      await api.uploadFile(
        config.owner,
        config.repo,
        folderPath,
        storage.utf8ToBase64('# GitVault Folder Placeholder'),
        `GitVault: Khởi tạo thư mục ${folderName}`,
        null,
        config.branch,
        config.token
      );
      showToast(`Đã tạo thư mục '${folderName}' thành công!`, 'success');
      loadDirectory(currentPath);
    } catch (err) {
      showToast(`Lỗi tạo thư mục: ${err.message}`, 'error');
    }
  });

  btnNewFile.addEventListener('click', () => {
    if (!config.token) {
      showToast('Cần có GitHub Token để tạo tệp tin.', 'error');
      openSettingsModal();
      return;
    }
    inputNewFilename.value = '';
    inputNewFilecontent.value = '';
    newFileModal.style.display = 'flex';
    inputNewFilename.focus();
  });

  btnCloseNewFileModal.addEventListener('click', () => newFileModal.style.display = 'none');
  btnCancelNewFile.addEventListener('click', () => newFileModal.style.display = 'none');

  btnConfirmCreateFile.addEventListener('click', async () => {
    const filename = inputNewFilename.value.trim();
    if (!filename) {
      showToast('Vui lòng nhập tên tệp tin kèm phần mở rộng.', 'error');
      return;
    }

    const filePath = currentPath ? `${currentPath}/${filename}` : filename;
    const content = inputNewFilecontent.value;

    try {
      newFileModal.style.display = 'none';
      showToast('Đang tạo và lưu tệp vào GitHub...', 'info');
      await api.uploadFile(
        config.owner,
        config.repo,
        filePath,
        storage.utf8ToBase64(content),
        `GitVault: Tạo tệp ${filename}`,
        null,
        config.branch,
        config.token
      );
      showToast(`Đã tạo tệp '${filename}' thành công!`, 'success');
      loadDirectory(currentPath);
    } catch (err) {
      showToast(`Lỗi tạo tệp: ${err.message}`, 'error');
    }
  });

  // ==========================================================================
  // File Previewer & Live Editor Modal
  // ==========================================================================
  async function openFilePreview(item) {
    previewFileTitle.textContent = item.name;
    const typeInfo = storage.getFileTypeInfo(item.name);
    previewFileIcon.className = `${typeInfo.icon} ${typeInfo.color}`;

    const cdnUrls = api.getPublicUrls(config.owner, config.repo, item.path, config.branch);
    btnPreviewDownload.href = item.download_url || cdnUrls.raw;
    btnPreviewDownload.setAttribute('download', item.name);

    btnPreviewCopyCdn.onclick = () => {
      navigator.clipboard.writeText(cdnUrls.jsdelivr);
      showToast('Đã sao chép jsDelivr CDN link!', 'success');
    };

    btnPreviewDelete.onclick = async () => {
      if (!config.token) {
        showToast('Cần có GitHub Token để xóa tệp.', 'error');
        return;
      }
      if (confirm(`Bạn có chắc chắn muốn xóa tệp '${item.name}' khỏi GitHub Repository?`)) {
        try {
          showToast('Đang xóa tệp khỏi GitHub...', 'info');
          await api.deleteFile(config.owner, config.repo, item.path, item.sha, `GitVault: Xóa tệp ${item.name}`, config.branch, config.token);
          showToast(`Đã xóa tệp ${item.name}!`, 'success');
          previewModal.style.display = 'none';
          loadDirectory(currentPath);
        } catch (err) {
          showToast(`Lỗi xóa tệp: ${err.message}`, 'error');
        }
      }
    };

    previewModalBody.innerHTML = '<div class="spinner"></div><p style="text-align:center;">Đang tải nội dung tệp...</p>';
    previewModalFooter.style.display = 'none';
    previewModal.style.display = 'flex';

    try {
      const fileData = await api.getFileDetails(config.owner, config.repo, item.path, config.branch, config.token);
      const isTextOrCode = ['code', 'text'].includes(typeInfo.type) || item.name.endsWith('.json') || item.name.endsWith('.md');

      if (typeInfo.type === 'image') {
        previewModalBody.innerHTML = `
          <div class="preview-media-container">
            <img src="${cdnUrls.jsdelivr}" class="preview-image" alt="${item.name}">
          </div>
        `;
      } else if (typeInfo.type === 'video') {
        previewModalBody.innerHTML = `
          <div class="preview-media-container">
            <video controls autoplay style="max-width:100%; max-height:60vh; border-radius:8px;">
              <source src="${cdnUrls.raw}">
              Trình duyệt của bạn không hỗ trợ phát video.
            </video>
          </div>
        `;
      } else if (typeInfo.type === 'audio') {
        previewModalBody.innerHTML = `
          <div class="preview-media-container">
            <audio controls autoplay style="width:100%; max-width:500px;">
              <source src="${cdnUrls.raw}">
              Trình duyệt không hỗ trợ phát âm thanh.
            </audio>
          </div>
        `;
      } else if (typeInfo.type === 'pdf') {
        previewModalBody.innerHTML = `
          <iframe src="https://docs.google.com/viewer?url=${encodeURIComponent(cdnUrls.raw)}&embedded=true" style="width:100%; height:100%; min-height:550px; border:none; border-radius:8px;"></iframe>
        `;
      } else if (item.name.endsWith('.md') && typeof marked !== 'undefined') {
        const decodedContent = storage.base64ToUtf8(fileData.content || '');
        currentFileEditing = { name: item.name, path: item.path, sha: fileData.sha, content: decodedContent };

        previewModalBody.innerHTML = `
          <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.75rem;">
            <span style="font-size:0.8rem; color:var(--text-muted);">Markdown Preview / Editor</span>
            <button class="btn-secondary-sm" id="btn-toggle-md-mode"><i class="fa-solid fa-code"></i> Chuyển sang chỉnh sửa mã</button>
          </div>
          <div id="md-view-pane" class="preview-markdown-rendered">${marked.parse(decodedContent)}</div>
          <textarea id="md-edit-pane" class="preview-code-editor" style="display:none; height:450px;">${decodedContent}</textarea>
        `;

        const btnToggleMd = document.getElementById('btn-toggle-md-mode');
        const mdViewPane = document.getElementById('md-view-pane');
        const mdEditPane = document.getElementById('md-edit-pane');

        let isEditing = false;
        btnToggleMd.addEventListener('click', () => {
          isEditing = !isEditing;
          if (isEditing) {
            mdViewPane.style.display = 'none';
            mdEditPane.style.display = 'block';
            previewModalFooter.style.display = 'flex';
            btnToggleMd.innerHTML = '<i class="fa-regular fa-eye"></i> Xem trước hiển thị';
          } else {
            mdViewPane.innerHTML = marked.parse(mdEditPane.value);
            mdViewPane.style.display = 'block';
            mdEditPane.style.display = 'none';
            btnToggleMd.innerHTML = '<i class="fa-solid fa-code"></i> Chuyển sang chỉnh sửa mã';
          }
        });
      } else if (isTextOrCode) {
        const decodedContent = storage.base64ToUtf8(fileData.content || '');
        currentFileEditing = { name: item.name, path: item.path, sha: fileData.sha, content: decodedContent };

        previewModalBody.innerHTML = `
          <textarea id="code-editor-area" class="preview-code-editor" spellcheck="false">${decodedContent}</textarea>
        `;
        previewModalFooter.style.display = 'flex';
      } else {
        previewModalBody.innerHTML = `
          <div class="empty-state">
            <div class="empty-state-icon"><i class="${typeInfo.icon}"></i></div>
            <h3>Không thể xem trước tệp nhị phân</h3>
            <p>Định dạng này không hỗ trợ hiển thị trực tiếp. Bạn có thể tải xuống hoặc lấy link CDN.</p>
          </div>
        `;
      }
    } catch (err) {
      previewModalBody.innerHTML = `<div class="empty-state"><p class="text-danger">Lỗi đọc file: ${err.message}</p></div>`;
    }
  }

  btnClosePreview.addEventListener('click', () => {
    previewModal.style.display = 'none';
    currentFileEditing = null;
  });

  btnSaveFileChanges.addEventListener('click', async () => {
    if (!config.token) {
      showToast('Cần có GitHub Token để lưu thay đổi.', 'error');
      return;
    }
    if (!currentFileEditing) return;

    const editorArea = document.getElementById('code-editor-area') || document.getElementById('md-edit-pane');
    const newContent = editorArea ? editorArea.value : '';

    try {
      showToast('Đang commit thay đổi lên GitHub...', 'info');
      const updated = await api.uploadFile(
        config.owner,
        config.repo,
        currentFileEditing.path,
        storage.utf8ToBase64(newContent),
        `GitVault: Cập nhật ${currentFileEditing.name}`,
        currentFileEditing.sha,
        config.branch,
        config.token
      );

      currentFileEditing.sha = updated.content.sha;
      showToast(`Đã lưu thay đổi thành công! (Commit SHA: ${updated.commit.sha.substring(0, 7)})`, 'success');
      loadDirectory(currentPath);
    } catch (err) {
      showToast(`Lỗi lưu thay đổi: ${err.message}`, 'error');
    }
  });

  // ==========================================================================
  // TAB 2: Data Vault (JSON Database Engine)
  // ==========================================================================
  async function loadDatabaseData() {
    dbTableBody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding:2rem;"><div class="spinner"></div>Đang tải dữ liệu bảng...</td></tr>';
    dbEmptyState.style.display = 'none';

    try {
      const fileData = await api.getFileDetails(config.owner, config.repo, currentDbPath, config.branch, config.token);
      currentDbSha = fileData.sha;
      const jsonString = storage.base64ToUtf8(fileData.content || '[]');
      currentDbRecords = storage.safeJsonParse(jsonString, []);
      renderDatabaseTable(currentDbRecords);
    } catch (err) {
      // If table file does not exist yet, we can initialize empty
      currentDbRecords = [];
      currentDbSha = null;
      renderDatabaseTable([]);
    }
  }

  function renderDatabaseTable(records) {
    dbTableBody.innerHTML = '';
    dbRecordCount.textContent = `${records.length} bản ghi`;

    if (!records || records.length === 0) {
      dbEmptyState.style.display = 'flex';
      return;
    }

    dbEmptyState.style.display = 'none';

    records.forEach((rec, idx) => {
      const tr = document.createElement('tr');

      const tagsHtml = (rec.tags || []).map(t => `<span class="table-tag">${t}</span>`).join(' ');
      const dateStr = rec.createdAt ? new Date(rec.createdAt).toLocaleDateString('vi-VN') : '—';

      tr.innerHTML = `
        <td><code>#${rec.id || idx + 1}</code></td>
        <td><strong>${rec.title || 'Không có tiêu đề'}</strong></td>
        <td><span class="table-tag">${rec.category || 'Mặc định'}</span></td>
        <td>${rec.content ? (rec.content.length > 50 ? rec.content.substring(0, 50) + '...' : rec.content) : '—'} ${tagsHtml}</td>
        <td>${dateStr}</td>
        <td>
          <div class="table-actions">
            <button class="btn-secondary-sm btn-edit-record" data-id="${rec.id}"><i class="fa-regular fa-pen-to-square"></i></button>
            <button class="btn-danger-sm btn-del-record" data-id="${rec.id}"><i class="fa-regular fa-trash-can"></i></button>
          </div>
        </td>
      `;

      // Event listeners for edit & delete
      tr.querySelector('.btn-edit-record').addEventListener('click', () => openRecordModal(rec));
      tr.querySelector('.btn-del-record').addEventListener('click', () => deleteDbRecord(rec.id));

      dbTableBody.appendChild(tr);
    });
  }

  // Search in database
  dbSearchInput.addEventListener('input', (e) => {
    const q = e.target.value.toLowerCase().trim();
    if (!q) {
      renderDatabaseTable(currentDbRecords);
      return;
    }
    const filtered = currentDbRecords.filter(r => 
      (r.title && r.title.toLowerCase().includes(q)) ||
      (r.category && r.category.toLowerCase().includes(q)) ||
      (r.content && r.content.toLowerCase().includes(q))
    );
    renderDatabaseTable(filtered);
  });

  // Add / Edit DB Record Modal
  function openRecordModal(record = null) {
    if (record) {
      recordModalTitle.textContent = 'Chỉnh Sửa Bản Ghi';
      recordEditId.value = record.id;
      recordInputTitle.value = record.title || '';
      recordInputCategory.value = record.category || '';
      recordInputContent.value = record.content || '';
      recordInputTags.value = (record.tags || []).join(', ');
    } else {
      recordModalTitle.textContent = 'Thêm Bản Ghi Mới Vào Database';
      recordEditId.value = '';
      recordInputTitle.value = '';
      recordInputCategory.value = '';
      recordInputContent.value = '';
      recordInputTags.value = '';
    }
    recordModal.style.display = 'flex';
    recordInputTitle.focus();
  }

  btnAddDbRecord.addEventListener('click', () => {
    if (!config.token) {
      showToast('Cần có GitHub Token để thêm dữ liệu vào Repository.', 'error');
      openSettingsModal();
      return;
    }
    openRecordModal(null);
  });

  btnCloseRecordModal.addEventListener('click', () => recordModal.style.display = 'none');
  btnCancelRecord.addEventListener('click', () => recordModal.style.display = 'none');

  btnSaveRecord.addEventListener('click', async () => {
    const title = recordInputTitle.value.trim();
    if (!title) {
      showToast('Vui lòng nhập tiêu đề cho bản ghi.', 'error');
      return;
    }

    const editId = recordEditId.value;
    const category = recordInputCategory.value.trim() || 'Chung';
    const content = recordInputContent.value.trim();
    const tags = recordInputTags.value.split(',').map(t => t.trim()).filter(Boolean);

    let updatedRecords = [...currentDbRecords];

    if (editId) {
      // Update existing
      updatedRecords = updatedRecords.map(r => {
        if (r.id === editId) {
          return { ...r, title, category, content, tags, updatedAt: new Date().toISOString() };
        }
        return r;
      });
    } else {
      // Add new
      const newRecord = {
        id: 'rec_' + Date.now().toString(36),
        title,
        category,
        content,
        tags,
        createdAt: new Date().toISOString()
      };
      updatedRecords.unshift(newRecord);
    }

    try {
      recordModal.style.display = 'none';
      showToast('Đang commit dữ liệu JSON vào GitHub...', 'info');

      const jsonPayload = JSON.stringify(updatedRecords, null, 2);
      const res = await api.uploadFile(
        config.owner,
        config.repo,
        currentDbPath,
        storage.utf8ToBase64(jsonPayload),
        `GitVault DB: ${editId ? 'Cập nhật' : 'Thêm'} bản ghi '${title}'`,
        currentDbSha,
        config.branch,
        config.token
      );

      currentDbSha = res.content.sha;
      currentDbRecords = updatedRecords;
      renderDatabaseTable(currentDbRecords);
      showToast('Đã lưu bản ghi thành công vào GitHub!', 'success');
    } catch (err) {
      showToast(`Lỗi lưu dữ liệu: ${err.message}`, 'error');
    }
  });

  async function deleteDbRecord(recordId) {
    if (!config.token) {
      showToast('Cần có GitHub Token để xóa bản ghi.', 'error');
      return;
    }
    if (!confirm('Bạn có chắc chắn muốn xóa bản ghi này?')) return;

    const updatedRecords = currentDbRecords.filter(r => r.id !== recordId);
    try {
      showToast('Đang xóa bản ghi và cập nhật GitHub...', 'info');
      const jsonPayload = JSON.stringify(updatedRecords, null, 2);
      const res = await api.uploadFile(
        config.owner,
        config.repo,
        currentDbPath,
        storage.utf8ToBase64(jsonPayload),
        `GitVault DB: Xóa bản ghi ${recordId}`,
        currentDbSha,
        config.branch,
        config.token
      );

      currentDbSha = res.content.sha;
      currentDbRecords = updatedRecords;
      renderDatabaseTable(currentDbRecords);
      showToast('Đã xóa bản ghi thành công!', 'success');
    } catch (err) {
      showToast(`Lỗi xóa bản ghi: ${err.message}`, 'error');
    }
  }

  // Export DB
  btnExportDb.addEventListener('click', () => {
    const jsonStr = JSON.stringify(currentDbRecords, null, 2);
    const blob = new Blob([jsonStr], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `gitvault_export_${Date.now()}.json`;
    a.click();
    URL.revokeObjectURL(url);
    showToast('Đã tải xuống file JSON dữ liệu!', 'success');
  });

  // Create new DB table
  btnNewDbTable.addEventListener('click', () => {
    const tableName = prompt('Nhập tên file bảng dữ liệu mới (ví dụ: data/products.json hoặc data/bookmarks.json):', 'data/products.json');
    if (tableName) {
      currentDbPath = tableName.trim();
      // Add to select options
      const opt = document.createElement('option');
      opt.value = currentDbPath;
      opt.textContent = currentDbPath;
      opt.selected = true;
      dbFileSelect.appendChild(opt);
      loadDatabaseData();
    }
  });

  dbFileSelect.addEventListener('change', (e) => {
    currentDbPath = e.target.value;
    loadDatabaseData();
  });

  // ==========================================================================
  // TAB 3: CDN Link Generator
  // ==========================================================================
  function updateCdnResults() {
    const filePath = cdnFilePathInput.value.trim() || 'images/sample.png';
    const urls = api.getPublicUrls(config.owner, config.repo, filePath, config.branch);

    cdnUrlJsdelivr.value = urls.jsdelivr;
    cdnUrlRaw.value = urls.raw;
    cdnUrlHtmlImg.value = `<img src="${urls.jsdelivr}" alt="${filePath.split('/').pop()}">`;
    cdnUrlMarkdown.value = `![${filePath.split('/').pop()}](${urls.jsdelivr})`;
  }

  btnGenerateCdn.addEventListener('click', updateCdnResults);
  cdnFilePathInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') updateCdnResults();
  });

  document.querySelectorAll('[data-copy-target]').forEach(btn => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-copy-target');
      const targetInput = document.getElementById(targetId);
      if (targetInput) {
        navigator.clipboard.writeText(targetInput.value);
        showToast('Đã sao chép vào bộ nhớ tạm!', 'success');
      }
    });
  });

  // ==========================================================================
  // Settings & Configuration Modal
  // ==========================================================================
  function openSettingsModal() {
    inputRepoOwner.value = config.owner;
    inputRepoName.value = config.repo;
    inputRepoBranch.value = config.branch || 'main';
    inputRepoToken.value = config.token || '';
    connectionFeedback.style.display = 'none';
    settingsModal.style.display = 'flex';
  }

  btnOpenSettings.addEventListener('click', openSettingsModal);
  btnCloseSettings.addEventListener('click', () => settingsModal.style.display = 'none');

  btnTogglePat.addEventListener('click', () => {
    const isPassword = inputRepoToken.type === 'password';
    inputRepoToken.type = isPassword ? 'text' : 'password';
    btnTogglePat.innerHTML = isPassword ? '<i class="fa-regular fa-eye-slash"></i>' : '<i class="fa-regular fa-eye"></i>';
  });

  btnTestConnection.addEventListener('click', async () => {
    const owner = inputRepoOwner.value.trim();
    const repo = inputRepoName.value.trim();
    const token = inputRepoToken.value.trim();

    if (!owner || !repo) {
      showFeedback('Vui lòng nhập đầy đủ Owner và Tên Repository.', 'error');
      return;
    }

    showFeedback('Đang kiểm tra kết nối tới GitHub...', 'info');

    try {
      const repoDetails = await api.getRepoDetails(owner, repo, token);
      let msg = `Kết nối thành công tới repo <strong>${repoDetails.full_name}</strong> (${repoDetails.private ? 'Private' : 'Public'}).`;
      if (token) {
        msg += `<br>Token hợp lệ với quyền truy cập đầy đủ.`;
      } else {
        msg += `<br>Chế độ: Đọc công khai (Chưa có Token).`;
      }
      showFeedback(msg, 'success');
    } catch (err) {
      showFeedback(`Lỗi kết nối: ${err.message}`, 'error');
    }
  });

  function showFeedback(html, type) {
    connectionFeedback.style.display = 'block';
    connectionFeedback.className = `connection-feedback ${type}`;
    connectionFeedback.innerHTML = html;
  }

  btnSaveSettings.addEventListener('click', () => {
    const owner = inputRepoOwner.value.trim();
    const repo = inputRepoName.value.trim();
    const branch = inputRepoBranch.value.trim() || 'main';
    const token = inputRepoToken.value.trim();

    if (!owner || !repo) {
      showToast('Vui lòng điền đủ thông tin Repository.', 'error');
      return;
    }

    config = { owner, repo, branch, token };
    storage.saveConfig(config);
    settingsModal.style.display = 'none';

    updateHeaderStats();
    updateCdnResults();
    loadDirectory('');
    showToast('Đã lưu cấu hình và kết nối thành công!', 'success');
  });

  btnRefresh.addEventListener('click', () => {
    loadDirectory(currentPath);
    showToast('Đã làm mới dữ liệu!', 'info');
  });

  // ==========================================================================
  // Application Bootstrap
  // ==========================================================================
  updateHeaderStats();
  updateCdnResults();
  loadDirectory('');
});
