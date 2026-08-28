/**
 * EduVault - GitHub REST API v3 Integration Module
 * Handles all academic repository communications, CRUD commits, and CDN URLs.
 */

class GitHubAPI {
  constructor() {
    this.baseUrl = 'https://api.github.com';
  }

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

  async getRepoDetails(owner, repo, token) {
    try {
      const res = await fetch(`${this.baseUrl}/repos/${owner}/${repo}`, {
        headers: this.getHeaders(token)
      });
      if (res.status === 404) throw new Error('Kho lưu trữ không tồn tại hoặc ở chế độ Private.');
      if (res.status === 401) throw new Error('Token không hợp lệ hoặc đã hết hạn.');
      if (!res.ok) throw new Error(`Lỗi kết nối GitHub (${res.status})`);
      return await res.json();
    } catch (e) {
      console.error('Lỗi lấy thông tin repo:', e);
      throw e;
    }
  }

  async getContents(owner, repo, path = '', branch = 'main', token = '') {
    try {
      const cleanPath = path.replace(/^\/+|\/+$/g, '');
      const url = `${this.baseUrl}/repos/${owner}/${repo}/contents/${cleanPath}${branch ? `?ref=${encodeURIComponent(branch)}` : ''}`;
      
      const res = await fetch(url, {
        headers: this.getHeaders(token),
        cache: 'no-cache'
      });

      if (res.status === 404) return [];
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.message || `Lỗi tải danh mục (${res.status})`);
      }

      const data = await res.json();
      return Array.isArray(data) ? data : [data];
    } catch (e) {
      console.error(`Lỗi đọc thư mục '${path}':`, e);
      throw e;
    }
  }

  async getFileDetails(owner, repo, path, branch = 'main', token = '') {
    try {
      const cleanPath = path.replace(/^\/+|\/+$/g, '');
      const url = `${this.baseUrl}/repos/${owner}/${repo}/contents/${cleanPath}${branch ? `?ref=${encodeURIComponent(branch)}` : ''}`;
      
      const res = await fetch(url, {
        headers: this.getHeaders(token),
        cache: 'no-cache'
      });

      if (!res.ok) throw new Error(`Không thể đọc tệp (${res.status})`);
      return await res.json();
    } catch (e) {
      console.error(`Lỗi lấy tệp '${path}':`, e);
      throw e;
    }
  }

  async uploadFile(owner, repo, path, base64Content, commitMessage = '', sha = null, branch = 'main', token = '') {
    if (!token) {
      throw new Error('Bạn cần nhập GitHub Token (PAT) trong phần Cấu Hình để tải lên tài liệu.');
    }

    try {
      const cleanPath = path.replace(/^\/+|\/+$/g, '');
      const url = `${this.baseUrl}/repos/${owner}/${repo}/contents/${cleanPath}`;

      const payload = {
        message: commitMessage || `EduVault: Lưu ${cleanPath}`,
        content: base64Content,
        branch: branch || 'main'
      };
      if (sha) payload.sha = sha;

      const res = await fetch(url, {
        method: 'PUT',
        headers: this.getHeaders(token),
        body: JSON.stringify(payload)
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        if (res.status === 401 || res.status === 403) {
          throw new Error('Token không đủ quyền ghi (cần quyền Contents: Read and Write).');
        }
        throw new Error(err.message || `Lỗi tải lên (${res.status})`);
      }

      return await res.json();
    } catch (e) {
      console.error(`Lỗi upload tệp '${path}':`, e);
      throw e;
    }
  }

  async deleteFile(owner, repo, path, sha, commitMessage = '', branch = 'main', token = '') {
    if (!token) throw new Error('Cần có GitHub Token để xóa tài liệu.');

    try {
      const cleanPath = path.replace(/^\/+|\/+$/g, '');
      const url = `${this.baseUrl}/repos/${owner}/${repo}/contents/${cleanPath}`;

      const payload = {
        message: commitMessage || `EduVault: Xóa ${cleanPath}`,
        sha: sha,
        branch: branch || 'main'
      };

      const res = await fetch(url, {
        method: 'DELETE',
        headers: this.getHeaders(token),
        body: JSON.stringify(payload)
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.message || `Lỗi xóa tệp (${res.status})`);
      }

      return await res.json();
    } catch (e) {
      console.error(`Lỗi xóa tệp '${path}':`, e);
      throw e;
    }
  }

  getPublicUrls(owner, repo, path, branch = 'main') {
    const cleanPath = path.replace(/^\/+|\/+$/g, '');
    return {
      jsdelivr: `https://cdn.jsdelivr.net/gh/${owner}/${repo}@${branch}/${cleanPath}`,
      raw: `https://raw.githubusercontent.com/${owner}/${repo}/${branch}/${cleanPath}`,
      githubWeb: `https://github.com/${owner}/${repo}/blob/${branch}/${cleanPath}`
    };
  }
}

// Attach globally
window.GitHubAPI = GitHubAPI;
