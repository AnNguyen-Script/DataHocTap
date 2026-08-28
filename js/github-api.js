/**
 * GitVault - GitHub REST API v3 Integration Module
 * Handles all CRUD operations, authentication, file uploading, rate-limiting, and CDN resolutions.
 */

class GitHubAPI {
  constructor() {
    this.baseUrl = 'https://api.github.com';
  }

  /**
   * Generates authorization & standard headers for GitHub API requests
   */
  getHeaders(token) {
    const headers = {
      'Accept': 'application/vnd.github.v3+json',
      'X-GitHub-Api-Version': '2022-11-28'
    };
    if (token && token.trim() !== '') {
      headers['Authorization'] = `token ${token.trim()}`;
    }
    return headers;
  }

  /**
   * Check rate limits & token validity
   */
  async checkRateLimit(token) {
    try {
      const response = await fetch(`${this.baseUrl}/rate_limit`, {
        headers: this.getHeaders(token)
      });
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Lỗi khi kiểm tra Rate Limit:', error);
      throw error;
    }
  }

  /**
   * Validate repository existence & permissions
   */
  async getRepoDetails(owner, repo, token) {
    try {
      const response = await fetch(`${this.baseUrl}/repos/${owner}/${repo}`, {
        headers: this.getHeaders(token)
      });

      if (response.status === 404) {
        throw new Error('Repository không tồn tại hoặc ở chế độ Private (cần có Token hợp lệ để truy cập).');
      }
      if (response.status === 401) {
        throw new Error('Token không hợp lệ hoặc đã hết hạn.');
      }
      if (!response.ok) {
        throw new Error(`Lỗi kết nối GitHub (${response.status}): ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Lỗi khi lấy thông tin Repo:', error);
      throw error;
    }
  }

  /**
   * List contents of a directory (files and folders)
   */
  async getContents(owner, repo, path = '', branch = 'main', token = '') {
    try {
      const cleanPath = path.replace(/^\/+|\/+$/g, '');
      const url = `${this.baseUrl}/repos/${owner}/${repo}/contents/${cleanPath}${branch ? `?ref=${encodeURIComponent(branch)}` : ''}`;
      
      const response = await fetch(url, {
        headers: this.getHeaders(token),
        cache: 'no-cache'
      });

      if (response.status === 404) {
        return []; // Directory might be empty or root has no items
      }
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || `Lỗi lấy danh sách tệp (${response.status})`);
      }

      const data = await response.json();
      return Array.isArray(data) ? data : [data];
    } catch (error) {
      console.error(`Lỗi khi đọc thư mục '${path}':`, error);
      throw error;
    }
  }

  /**
   * Get single file metadata & base64 content
   */
  async getFileDetails(owner, repo, path, branch = 'main', token = '') {
    try {
      const cleanPath = path.replace(/^\/+|\/+$/g, '');
      const url = `${this.baseUrl}/repos/${owner}/${repo}/contents/${cleanPath}${branch ? `?ref=${encodeURIComponent(branch)}` : ''}`;
      
      const response = await fetch(url, {
        headers: this.getHeaders(token),
        cache: 'no-cache'
      });

      if (!response.ok) {
        throw new Error(`Không tìm thấy tệp hoặc lỗi truy cập (${response.status})`);
      }

      return await response.json();
    } catch (error) {
      console.error(`Lỗi khi lấy thông tin tệp '${path}':`, error);
      throw error;
    }
  }

  /**
   * Upload (Create or Update) a file in the repository
   * @param {string} owner - Repo owner
   * @param {string} repo - Repo name
   * @param {string} path - Relative file path (e.g. "images/photo.jpg")
   * @param {string} base64Content - Base64 encoded string
   * @param {string} commitMessage - Commit message
   * @param {string|null} sha - File SHA (required when updating existing file)
   * @param {string} branch - Branch name
   * @param {string} token - Personal Access Token with repo write permissions
   */
  async uploadFile(owner, repo, path, base64Content, commitMessage = '', sha = null, branch = 'main', token = '') {
    if (!token) {
      throw new Error('Bạn cần nhập GitHub Token (PAT) có quyền ghi (Contents: write) để tải lên hoặc chỉnh sửa tệp.');
    }

    try {
      const cleanPath = path.replace(/^\/+|\/+$/g, '');
      const url = `${this.baseUrl}/repos/${owner}/${repo}/contents/${cleanPath}`;

      const payload = {
        message: commitMessage || `GitVault: ${sha ? 'Cập nhật' : 'Tải lên'} ${cleanPath}`,
        content: base64Content,
        branch: branch || 'main'
      };

      if (sha) {
        payload.sha = sha;
      }

      const response = await fetch(url, {
        method: 'PUT',
        headers: this.getHeaders(token),
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        if (response.status === 409) {
          throw new Error('Xung đột phiên bản (Conflict SHA). Vui lòng làm mới trang và thử lại.');
        }
        if (response.status === 401 || response.status === 403) {
          throw new Error('Token không có đủ quyền ghi vào repository này. Vui lòng kiểm tra quyền Contents (Read & Write).');
        }
        throw new Error(errorData.message || `Lỗi tải lên tệp (${response.status})`);
      }

      return await response.json();
    } catch (error) {
      console.error(`Lỗi upload tệp '${path}':`, error);
      throw error;
    }
  }

  /**
   * Delete a file in repository
   */
  async deleteFile(owner, repo, path, sha, commitMessage = '', branch = 'main', token = '') {
    if (!token) {
      throw new Error('Bạn cần nhập GitHub Token (PAT) để xóa tệp.');
    }

    try {
      const cleanPath = path.replace(/^\/+|\/+$/g, '');
      const url = `${this.baseUrl}/repos/${owner}/${repo}/contents/${cleanPath}`;

      const payload = {
        message: commitMessage || `GitVault: Xóa ${cleanPath}`,
        sha: sha,
        branch: branch || 'main'
      };

      const response = await fetch(url, {
        method: 'DELETE',
        headers: this.getHeaders(token),
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || `Lỗi khi xóa tệp (${response.status})`);
      }

      return await response.json();
    } catch (error) {
      console.error(`Lỗi xóa tệp '${path}':`, error);
      throw error;
    }
  }

  /**
   * Generate fast CDN and Public URLs for files in a public repo
   */
  getPublicUrls(owner, repo, path, branch = 'main') {
    const cleanPath = path.replace(/^\/+|\/+$/g, '');
    return {
      jsdelivr: `https://cdn.jsdelivr.net/gh/${owner}/${repo}@${branch}/${cleanPath}`,
      raw: `https://raw.githubusercontent.com/${owner}/${repo}/${branch}/${cleanPath}`,
      githubWeb: `https://github.com/${owner}/${repo}/blob/${branch}/${cleanPath}`,
      statically: `https://cdn.statically.io/gh/${owner}/${repo}/${branch}/${cleanPath}`
    };
  }
}

// Attach globally
window.GitHubAPI = GitHubAPI;
