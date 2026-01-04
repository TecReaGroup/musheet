/**
 * MuSheet Admin Panel - JavaScript Application
 * Handles all client-side logic for the admin dashboard
 */

// API Configuration
const API_BASE = window.location.protocol + '//' + window.location.hostname + ':8080';

// Application State
const state = {
    token: localStorage.getItem('admin_token'),
    userId: localStorage.getItem('admin_user_id') ? parseInt(localStorage.getItem('admin_user_id')) : null,
    username: localStorage.getItem('admin_username'),
    avatarPath: localStorage.getItem('admin_avatar_path'),
    currentPage: 'dashboard',
    usersPage: 0,
    teamsPage: 0,
    pageSize: 20,
    currentTeamId: null,
    allUsers: []
};

// ============================================
// API HELPER FUNCTIONS
// ============================================

/**
 * Make a Serverpod RPC call
 * Serverpod expects: { "method": "methodName", ...params }
 */
async function rpcCall(endpoint, method, params = {}) {
    const url = `${API_BASE}/${endpoint}`;
    const headers = {
        'Content-Type': 'application/json'
    };

    if (state.token) {
        headers['Authorization'] = `Bearer ${state.token}`;
    }

    // Serverpod RPC format: { method: "methodName", param1: value1, ... }
    const body = {
        method: method,
        ...params
    };

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers,
            body: JSON.stringify(body)
        });

        const text = await response.text();

        // Try to parse as JSON
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            console.error('Invalid JSON response:', text);
            throw new Error(text || 'Invalid server response');
        }

        // Check for Serverpod error format
        if (data.error) {
            throw new Error(data.error);
        }

        // Check for exception format
        if (data.exception) {
            throw new Error(data.exception.message || data.exception);
        }

        return data;
    } catch (error) {
        console.error(`RPC Error [${endpoint}.${method}]:`, error);
        throw error;
    }
}

// ============================================
// AUTHENTICATION
// ============================================

async function checkNeedsAdminRegistration() {
    try {
        const result = await rpcCall('adminUser', 'needsAdminRegistration', {});
        return result === true;
    } catch (e) {
        console.error('Failed to check admin registration:', e);
        return false;
    }
}

async function login(username, password) {
    try {
        const result = await rpcCall('auth', 'login', { username, password });

        if (result.success) {
            // Check if user is admin
            if (!result.user?.isAdmin) {
                throw new Error('Admin access required');
            }

            state.token = result.token;
            state.userId = result.user.id;
            state.username = result.user.displayName || result.user.username;
            state.avatarPath = result.user.avatarPath || null;

            localStorage.setItem('admin_token', result.token);
            localStorage.setItem('admin_user_id', result.user.id.toString());
            localStorage.setItem('admin_username', state.username);
            if (state.avatarPath) {
                localStorage.setItem('admin_avatar_path', state.avatarPath);
            } else {
                localStorage.removeItem('admin_avatar_path');
            }

            return { success: true };
        } else {
            throw new Error(result.errorMessage || 'Login failed');
        }
    } catch (error) {
        throw error;
    }
}

async function signup(username, password, displayName) {
    try {
        const result = await rpcCall('auth', 'register', {
            username,
            password,
            displayName: displayName || null
        });

        if (result.success) {
            // Check if user is admin (first user becomes admin)
            if (!result.user?.isAdmin) {
                throw new Error('Admin access required. Only admins can access this console.');
            }

            state.token = result.token;
            state.userId = result.user.id;
            state.username = result.user.displayName || result.user.username;
            state.avatarPath = result.user.avatarPath || null;

            localStorage.setItem('admin_token', result.token);
            localStorage.setItem('admin_user_id', result.user.id.toString());
            localStorage.setItem('admin_username', state.username);
            if (state.avatarPath) {
                localStorage.setItem('admin_avatar_path', state.avatarPath);
            } else {
                localStorage.removeItem('admin_avatar_path');
            }

            return { success: true, isAdmin: result.user.isAdmin };
        } else {
            throw new Error(result.errorMessage || 'Sign up failed');
        }
    } catch (error) {
        throw error;
    }
}

async function registerAdmin(username, password, displayName) {
    // Legacy function - now uses signup
    return await signup(username, password, displayName);
}

function logout() {
    state.token = null;
    state.userId = null;
    state.username = null;
    state.avatarPath = null;

    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user_id');
    localStorage.removeItem('admin_username');
    localStorage.removeItem('admin_avatar_path');

    showPage('login');
}

// ============================================
// DASHBOARD API
// ============================================

async function getDashboardStats() {
    return await rpcCall('admin', 'getDashboardStats', { adminUserId: state.userId });
}

async function getAllUsers(page = 0, pageSize = 20) {
    return await rpcCall('admin', 'getAllUsers', {
        adminUserId: state.userId,
        page,
        pageSize
    });
}

async function getAllTeams(page = 0, pageSize = 20) {
    return await rpcCall('admin', 'getAllTeams', {
        adminUserId: state.userId,
        page,
        pageSize
    });
}

// ============================================
// USER MANAGEMENT API
// ============================================

async function createUser(username, password, displayName, isAdmin) {
    return await rpcCall('adminUser', 'createUser', {
        adminUserId: state.userId,
        username,
        initialPassword: password,
        displayName: displayName || null,
        isAdmin
    });
}

async function deactivateUser(userId) {
    return await rpcCall('admin', 'deactivateUser', {
        adminUserId: state.userId,
        targetUserId: userId
    });
}

async function reactivateUser(userId) {
    return await rpcCall('admin', 'reactivateUser', {
        adminUserId: state.userId,
        targetUserId: userId
    });
}

async function deleteUser(userId) {
    return await rpcCall('admin', 'deleteUser', {
        adminUserId: state.userId,
        targetUserId: userId
    });
}

async function promoteToAdmin(userId) {
    return await rpcCall('admin', 'promoteToAdmin', {
        adminUserId: state.userId,
        targetUserId: userId
    });
}

async function demoteFromAdmin(userId) {
    return await rpcCall('admin', 'demoteFromAdmin', {
        adminUserId: state.userId,
        targetUserId: userId
    });
}

async function resetUserPassword(userId) {
    return await rpcCall('adminUser', 'resetUserPassword', {
        adminUserId: state.userId,
        userId
    });
}

// ============================================
// TEAM MANAGEMENT API
// ============================================

async function createTeam(name, description) {
    return await rpcCall('team', 'createTeam', {
        adminUserId: state.userId,
        name,
        description: description || null
    });
}

async function deleteTeam(teamId) {
    return await rpcCall('admin', 'deleteTeam', {
        adminUserId: state.userId,
        teamId
    });
}

async function getTeamMembers(teamId) {
    return await rpcCall('team', 'getTeamMembers', {
        adminUserId: state.userId,
        teamId
    });
}

async function addMemberToTeam(teamId, userId) {
    // Per TEAM_SYNC_LOGIC.md: All members have 'member' role (成员平等)
    return await rpcCall('team', 'addMemberToTeam', {
        adminUserId: state.userId,
        teamId,
        userId
    });
}

async function removeMemberFromTeam(teamId, userId) {
    return await rpcCall('team', 'removeMemberFromTeam', {
        adminUserId: state.userId,
        teamId,
        userId
    });
}

// NOTE: updateMemberRole removed - all members have 'member' role (per TEAM_SYNC_LOGIC.md: 成员平等)

// ============================================
// UI HELPER FUNCTIONS
// ============================================

async function loadUserAvatar(userId) {
    try {
        const result = await rpcCall('profile', 'getAvatar', { userId });

        if (result && typeof result === 'string') {
            // Serverpod ByteData is serialized as: decode('base64string', 'base64')
            const prefix = "decode('";
            const suffix = "', 'base64')";

            if (result.startsWith(prefix) && result.endsWith(suffix)) {
                let base64 = result.slice(prefix.length, result.length - suffix.length);

                // Clean up base64 string (remove whitespace, newlines)
                base64 = base64.replace(/[\s\r\n]/g, '');

                // Convert base64 to Blob URL (handles large images better)
                const binaryString = atob(base64);
                const bytes = new Uint8Array(binaryString.length);
                for (let i = 0; i < binaryString.length; i++) {
                    bytes[i] = binaryString.charCodeAt(i);
                }
                const blob = new Blob([bytes], { type: 'image/png' });
                return URL.createObjectURL(blob);
            }
        }
    } catch (e) {
        console.log('Failed to load avatar:', e);
    }
    return null;
}

function showPage(page) {
    document.getElementById('login-page').classList.toggle('hidden', page !== 'login');
    document.getElementById('dashboard-page').classList.toggle('hidden', page === 'login');

    if (page !== 'login') {
        const displayName = state.username || 'Admin';
        document.getElementById('current-user-name').textContent = displayName;

        // Update user avatar
        const avatarContainer = document.getElementById('user-avatar-container');
        if (avatarContainer) {
            // Show initials first
            avatarContainer.innerHTML = `<span class="avatar-initials">${getInitials(displayName)}</span>`;

            // Then try to load avatar if user has one
            if (state.avatarPath && state.userId) {
                loadUserAvatar(state.userId).then(avatarDataUrl => {
                    if (avatarDataUrl) {
                        avatarContainer.innerHTML = `<img src="${avatarDataUrl}" alt="Avatar" class="avatar-img">`;
                    }
                });
            }
        }
    }
}

function getInitials(name) {
    if (!name) return 'A';
    const parts = name.trim().split(/\s+/);
    if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
}

function showSection(section) {
    state.currentPage = section;

    // Update navigation
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.toggle('active', item.dataset.page === section);
    });

    // Update page title
    const titles = {
        dashboard: 'Dashboard',
        users: 'User Management',
        teams: 'Team Management'
    };
    document.getElementById('page-title').textContent = titles[section] || section;

    // Show correct content section
    document.getElementById('dashboard-content').classList.toggle('hidden', section !== 'dashboard');
    document.getElementById('users-content').classList.toggle('hidden', section !== 'users');
    document.getElementById('teams-content').classList.toggle('hidden', section !== 'teams');

    // Load data for section
    if (section === 'dashboard') {
        loadDashboard();
    } else if (section === 'users') {
        loadUsers();
    } else if (section === 'teams') {
        loadTeams();
    }
}

function showModal(modalId) {
    document.getElementById(modalId).classList.remove('hidden');
}

function hideModal(modalId) {
    document.getElementById(modalId).classList.add('hidden');
}

function showToast(type, title, message) {
    const container = document.getElementById('toast-container');
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;

    const icons = {
        success: 'fas fa-check',
        error: 'fas fa-exclamation-triangle',
        info: 'fas fa-info-circle'
    };

    toast.innerHTML = `
        <div class="toast-icon">
            <i class="${icons[type]}"></i>
        </div>
        <div class="toast-content">
            <div class="toast-title">${title}</div>
            <div class="toast-message">${message}</div>
        </div>
    `;

    container.appendChild(toast);

    setTimeout(() => {
        toast.classList.add('toast-out');
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

function formatBytes(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function formatDate(dateStr) {
    if (!dateStr) return '-';
    const date = new Date(dateStr);
    return date.toLocaleDateString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
    });
}

function showConfirm(title, message, onConfirm, buttonClass = 'btn-danger') {
    document.getElementById('confirm-title').textContent = title;
    document.getElementById('confirm-message').textContent = message;

    const confirmBtn = document.getElementById('confirm-btn');
    confirmBtn.className = `btn ${buttonClass}`;
    confirmBtn.onclick = () => {
        hideModal('confirm-modal');
        onConfirm();
    };

    showModal('confirm-modal');
}

// ============================================
// DATA LOADING FUNCTIONS
// ============================================

async function loadDashboard() {
    try {
        const stats = await getDashboardStats();

        document.getElementById('stat-total-users').textContent = stats.totalMembers || 0;
        document.getElementById('stat-active-users').textContent = stats.activeMembers7d || 0;
        document.getElementById('stat-total-teams').textContent = stats.totalTeams || 0;
        document.getElementById('stat-total-scores').textContent = stats.totalScores || 0;
        document.getElementById('stat-storage').textContent = formatBytes(stats.totalStorageUsed || 0);

        // Render teams table
        const tbody = document.getElementById('dashboard-teams-body');
        if (stats.teams && stats.teams.length > 0) {
            tbody.innerHTML = stats.teams.map(team => `
                <tr>
                    <td><strong>${escapeHtml(team.name)}</strong></td>
                    <td><span class="badge badge-primary"><i class="fas fa-users"></i> ${team.memberCount}</span></td>
                    <td><span class="badge badge-secondary"><i class="fas fa-file-pdf"></i> ${team.sharedScores}</span></td>
                </tr>
            `).join('');
        } else {
            tbody.innerHTML = `
                <tr>
                    <td colspan="3" class="text-center text-muted">No teams yet</td>
                </tr>
            `;
        }
    } catch (error) {
        console.error('Failed to load dashboard:', error);
        showToast('error', 'Error', 'Failed to load dashboard data');
    }
}

async function loadUsers() {
    try {
        const users = await getAllUsers(state.usersPage, state.pageSize);
        state.allUsers = users;

        const tbody = document.getElementById('users-table-body');
        if (users && users.length > 0) {
            tbody.innerHTML = users.map(user => `
                <tr>
                    <td>${user.id}</td>
                    <td><strong>${escapeHtml(user.username)}</strong></td>
                    <td>${escapeHtml(user.displayName || '-')}</td>
                    <td>
                        ${user.isAdmin
                            ? '<span class="badge badge-primary"><i class="fas fa-shield-alt"></i> Admin</span>'
                            : '<span class="badge badge-secondary">User</span>'
                        }
                    </td>
                    <td>
                        ${user.isDisabled
                            ? '<span class="badge badge-danger"><i class="fas fa-ban"></i> Disabled</span>'
                            : '<span class="badge badge-success"><i class="fas fa-check"></i> Active</span>'
                        }
                    </td>
                    <td>${formatDate(user.createdAt)}</td>
                    <td>
                        <div class="action-buttons">
                            ${user.id !== state.userId ? `
                                ${user.isDisabled
                                    ? `<button class="action-btn success" title="Activate" onclick="handleReactivateUser(${user.id})"><i class="fas fa-check"></i></button>`
                                    : `<button class="action-btn" title="Deactivate" onclick="handleDeactivateUser(${user.id})"><i class="fas fa-ban"></i></button>`
                                }
                                ${user.isAdmin
                                    ? `<button class="action-btn" title="Demote" onclick="handleDemoteUser(${user.id})"><i class="fas fa-user-minus"></i></button>`
                                    : `<button class="action-btn" title="Promote" onclick="handlePromoteUser(${user.id})"><i class="fas fa-user-shield"></i></button>`
                                }
                                <button class="action-btn" title="Reset Password" onclick="handleResetPassword(${user.id})"><i class="fas fa-key"></i></button>
                                <button class="action-btn danger" title="Delete" onclick="handleDeleteUser(${user.id}, '${escapeHtml(user.username)}')"><i class="fas fa-trash"></i></button>
                            ` : `
                                <span class="text-muted">Current User</span>
                            `}
                        </div>
                    </td>
                </tr>
            `).join('');
        } else {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" class="text-center text-muted">No users found</td>
                </tr>
            `;
        }

        // Pagination
        renderPagination('users-pagination', state.usersPage, users.length, state.pageSize, (page) => {
            state.usersPage = page;
            loadUsers();
        });
    } catch (error) {
        console.error('Failed to load users:', error);
        showToast('error', 'Error', 'Failed to load users');
    }
}

async function loadTeams() {
    try {
        const teams = await getAllTeams(state.teamsPage, state.pageSize);

        const tbody = document.getElementById('teams-table-body');
        if (teams && teams.length > 0) {
            tbody.innerHTML = teams.map(team => `
                <tr>
                    <td>${team.id}</td>
                    <td><strong>${escapeHtml(team.name)}</strong></td>
                    <td><span class="badge badge-primary"><i class="fas fa-users"></i> ${team.memberCount}</span></td>
                    <td><span class="badge badge-secondary"><i class="fas fa-file-pdf"></i> ${team.sharedScores}</span></td>
                    <td>
                        <div class="action-buttons">
                            <button class="action-btn" title="View Members" onclick="handleViewTeamMembers(${team.id}, '${escapeHtml(team.name)}')"><i class="fas fa-users"></i></button>
                            <button class="action-btn danger" title="Delete" onclick="handleDeleteTeam(${team.id}, '${escapeHtml(team.name)}')"><i class="fas fa-trash"></i></button>
                        </div>
                    </td>
                </tr>
            `).join('');
        } else {
            tbody.innerHTML = `
                <tr>
                    <td colspan="5" class="text-center text-muted">No teams found</td>
                </tr>
            `;
        }

        // Pagination
        renderPagination('teams-pagination', state.teamsPage, teams.length, state.pageSize, (page) => {
            state.teamsPage = page;
            loadTeams();
        });
    } catch (error) {
        console.error('Failed to load teams:', error);
        showToast('error', 'Error', 'Failed to load teams');
    }
}

function renderPagination(containerId, currentPage, itemCount, pageSize, onPageChange) {
    const container = document.getElementById(containerId);
    const hasMore = itemCount >= pageSize;

    if (currentPage === 0 && !hasMore) {
        container.innerHTML = '';
        return;
    }

    container.innerHTML = `
        <button ${currentPage === 0 ? 'disabled' : ''} onclick="arguments[0].stopPropagation()">
            <i class="fas fa-chevron-left"></i> Previous
        </button>
        <button class="active">${currentPage + 1}</button>
        <button ${!hasMore ? 'disabled' : ''} onclick="arguments[0].stopPropagation()">
            Next <i class="fas fa-chevron-right"></i>
        </button>
    `;

    const buttons = container.querySelectorAll('button');
    buttons[0].onclick = () => onPageChange(currentPage - 1);
    buttons[2].onclick = () => onPageChange(currentPage + 1);
}

// ============================================
// USER ACTION HANDLERS
// ============================================

function handleDeactivateUser(userId) {
    showConfirm('Deactivate User', 'Are you sure you want to deactivate this user?', async () => {
        try {
            await deactivateUser(userId);
            showToast('success', 'Success', 'User deactivated');
            loadUsers();
        } catch (error) {
            showToast('error', 'Error', error.message || 'Failed to deactivate user');
        }
    });
}

function handleReactivateUser(userId) {
    showConfirm('Activate User', 'Are you sure you want to activate this user?', async () => {
        try {
            await reactivateUser(userId);
            showToast('success', 'Success', 'User activated');
            loadUsers();
        } catch (error) {
            showToast('error', 'Error', error.message || 'Failed to activate user');
        }
    }, 'btn-success');
}

function handlePromoteUser(userId) {
    showConfirm('Promote to Admin', 'Are you sure you want to give this user admin privileges?', async () => {
        try {
            await promoteToAdmin(userId);
            showToast('success', 'Success', 'User promoted to admin');
            loadUsers();
        } catch (error) {
            showToast('error', 'Error', error.message || 'Failed to promote user');
        }
    }, 'btn-primary');
}

function handleDemoteUser(userId) {
    showConfirm('Demote from Admin', 'Are you sure you want to remove admin privileges from this user?', async () => {
        try {
            await demoteFromAdmin(userId);
            showToast('success', 'Success', 'User demoted');
            loadUsers();
        } catch (error) {
            showToast('error', 'Error', error.message || 'Failed to demote user');
        }
    });
}

async function handleResetPassword(userId) {
    showConfirm('Reset Password', 'This will generate a new temporary password. Continue?', async () => {
        try {
            const tempPassword = await resetUserPassword(userId);
            showToast('success', 'Password Reset', `Temporary password: ${tempPassword}`);
            // Show password in a more visible way
            alert(`Temporary Password: ${tempPassword}\n\nPlease share this with the user securely.`);
        } catch (error) {
            showToast('error', 'Error', error.message || 'Failed to reset password');
        }
    }, 'btn-primary');
}

function handleDeleteUser(userId, username) {
    showConfirm('Delete User', `Are you sure you want to permanently delete user "${username}"? This action cannot be undone.`, async () => {
        try {
            await deleteUser(userId);
            showToast('success', 'Success', 'User deleted');
            loadUsers();
        } catch (error) {
            showToast('error', 'Error', error.message || 'Failed to delete user');
        }
    });
}

// ============================================
// TEAM ACTION HANDLERS
// ============================================

async function handleViewTeamMembers(teamId, teamName) {
    state.currentTeamId = teamId;
    document.getElementById('team-members-title').textContent = `${teamName} - Members`;
    showModal('team-members-modal');

    try {
        const members = await getTeamMembers(teamId);
        const tbody = document.getElementById('team-members-body');

        if (members && members.length > 0) {
            tbody.innerHTML = members.map(member => `
                <tr>
                    <td><strong>${escapeHtml(member.username)}</strong></td>
                    <td>${escapeHtml(member.displayName || '-')}</td>
                    <td>
                        <span class="role-badge">Member</span>
                    </td>
                    <td>${formatDate(member.joinedAt)}</td>
                    <td>
                        <button class="action-btn danger" title="Remove" onclick="handleRemoveMember(${teamId}, ${member.userId}, '${escapeHtml(member.username)}')">
                            <i class="fas fa-user-minus"></i>
                        </button>
                    </td>
                </tr>
            `).join('');
        } else {
            tbody.innerHTML = `
                <tr>
                    <td colspan="5" class="text-center text-muted">No members in this team</td>
                </tr>
            `;
        }
    } catch (error) {
        console.error('Failed to load team members:', error);
        showToast('error', 'Error', 'Failed to load team members');
    }
}

function handleDeleteTeam(teamId, teamName) {
    showConfirm('Delete Team', `Are you sure you want to permanently delete team "${teamName}"? All shared scores and members will be removed.`, async () => {
        try {
            await deleteTeam(teamId);
            showToast('success', 'Success', 'Team deleted');
            loadTeams();
            loadDashboard();
        } catch (error) {
            showToast('error', 'Error', error.message || 'Failed to delete team');
        }
    });
}

// NOTE: handleUpdateMemberRole removed - all members have 'member' role (per TEAM_SYNC_LOGIC.md: 成员平等)

function handleRemoveMember(teamId, userId, username) {
    showConfirm('Remove Member', `Remove "${username}" from this team?`, async () => {
        try {
            await removeMemberFromTeam(teamId, userId);
            showToast('success', 'Success', 'Member removed');
            handleViewTeamMembers(teamId, document.getElementById('team-members-title').textContent.split(' - ')[0]);
            loadTeams();
        } catch (error) {
            showToast('error', 'Error', error.message || 'Failed to remove member');
        }
    });
}

async function showAddMemberModal() {
    // Load all users for selection
    try {
        const users = await getAllUsers(0, 1000);
        const select = document.getElementById('member-user-id');
        select.innerHTML = '<option value="">-- Select User --</option>' +
            users.map(u => `<option value="${u.id}">${escapeHtml(u.username)} (${escapeHtml(u.displayName || 'No name')})</option>`).join('');
        showModal('add-member-modal');
    } catch (error) {
        showToast('error', 'Error', 'Failed to load users');
    }
}

// ============================================
// UTILITY FUNCTIONS
// ============================================

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ============================================
// EVENT LISTENERS
// ============================================

document.addEventListener('DOMContentLoaded', async () => {
    // Check if already logged in
    if (state.token && state.userId) {
        showPage('dashboard');
        showSection('dashboard');
    } else {
        showPage('login');

        // Check if needs first admin registration and update signup info
        const needsReg = await checkNeedsAdminRegistration();
        if (needsReg) {
            // Update the signup info text to indicate first user becomes admin
            const signupInfo = document.getElementById('signup-info');
            if (signupInfo) {
                signupInfo.textContent = 'First user will automatically become admin.';
                signupInfo.style.display = 'block';
            }
        } else {
            // Hide the info text for subsequent users
            const signupInfo = document.getElementById('signup-info');
            if (signupInfo) {
                signupInfo.textContent = 'Only admins can access this console.';
            }
        }
    }

    // Login form
    document.getElementById('login-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const errorEl = document.getElementById('login-error');
        errorEl.classList.add('hidden');

        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;

        try {
            await login(username, password);
            showPage('dashboard');
            showSection('dashboard');
        } catch (error) {
            errorEl.textContent = error.message || 'Login failed';
            errorEl.classList.remove('hidden');
        }
    });

    // Show register modal
    document.getElementById('show-register-btn')?.addEventListener('click', () => {
        showModal('register-modal');
    });

    // Register form (legacy)
    document.getElementById('register-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const errorEl = document.getElementById('register-error');
        errorEl.classList.add('hidden');

        const username = document.getElementById('reg-username').value;
        const password = document.getElementById('reg-password').value;
        const displayName = document.getElementById('reg-display-name').value;

        try {
            await registerAdmin(username, password, displayName);
            hideModal('register-modal');
            showPage('dashboard');
            showSection('dashboard');
            showToast('success', 'Welcome!', 'Admin account created successfully');
        } catch (error) {
            errorEl.textContent = error.message || 'Registration failed';
            errorEl.classList.remove('hidden');
        }
    });

    // Show signup modal
    document.getElementById('show-signup-btn').addEventListener('click', () => {
        document.getElementById('signup-form').reset();
        showModal('signup-modal');
    });

    // Signup form submission
    document.getElementById('signup-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const errorEl = document.getElementById('signup-error');
        errorEl.classList.add('hidden');

        const username = document.getElementById('signup-username').value;
        const password = document.getElementById('signup-password').value;
        const displayName = document.getElementById('signup-display-name').value;

        try {
            const result = await signup(username, password, displayName);
            hideModal('signup-modal');
            showPage('dashboard');
            showSection('dashboard');
            if (result.isAdmin) {
                showToast('success', 'Welcome!', 'Admin account created successfully');
            } else {
                showToast('success', 'Welcome!', 'Account created. Note: Only admins can access this console.');
            }
        } catch (error) {
            errorEl.textContent = error.message || 'Sign up failed';
            errorEl.classList.remove('hidden');
        }
    });

    // Navigation
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            showSection(item.dataset.page);
        });
    });

    // Logout
    document.getElementById('logout-btn').addEventListener('click', logout);

    // Refresh
    document.getElementById('refresh-btn').addEventListener('click', () => {
        showSection(state.currentPage);
        showToast('info', 'Refreshed', 'Data has been refreshed');
    });

    // Sidebar toggle (mobile)
    document.getElementById('sidebar-toggle').addEventListener('click', () => {
        document.querySelector('.sidebar').classList.toggle('open');
    });

    // Create user button
    document.getElementById('create-user-btn').addEventListener('click', () => {
        document.getElementById('create-user-form').reset();
        showModal('create-user-modal');
    });

    // Create user form
    document.getElementById('create-user-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const errorEl = document.getElementById('create-user-error');
        errorEl.classList.add('hidden');

        const username = document.getElementById('new-username').value;
        const password = document.getElementById('new-password').value;
        const displayName = document.getElementById('new-display-name').value;
        const isAdmin = document.getElementById('new-is-admin').checked;

        try {
            await createUser(username, password, displayName, isAdmin);
            hideModal('create-user-modal');
            showToast('success', 'Success', 'User created successfully');
            loadUsers();
        } catch (error) {
            errorEl.textContent = error.message || 'Failed to create user';
            errorEl.classList.remove('hidden');
        }
    });

    // Create team button
    document.getElementById('create-team-btn').addEventListener('click', () => {
        document.getElementById('create-team-form').reset();
        showModal('create-team-modal');
    });

    // Create team form
    document.getElementById('create-team-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const errorEl = document.getElementById('create-team-error');
        errorEl.classList.add('hidden');

        const name = document.getElementById('team-name').value;
        const description = document.getElementById('team-description').value;

        try {
            await createTeam(name, description);
            hideModal('create-team-modal');
            showToast('success', 'Success', 'Team created successfully');
            loadTeams();
            loadDashboard();
        } catch (error) {
            errorEl.textContent = error.message || 'Failed to create team';
            errorEl.classList.remove('hidden');
        }
    });

    // Add member button
    document.getElementById('add-member-btn').addEventListener('click', showAddMemberModal);

    // Add member form
    document.getElementById('add-member-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const errorEl = document.getElementById('add-member-error');
        errorEl.classList.add('hidden');

        const userId = parseInt(document.getElementById('member-user-id').value);
        // Role is always 'member' per design doc (成员平等)

        if (!userId) {
            errorEl.textContent = 'Please select a user';
            errorEl.classList.remove('hidden');
            return;
        }

        try {
            await addMemberToTeam(state.currentTeamId, userId);
            hideModal('add-member-modal');
            showToast('success', 'Success', 'Member added successfully');
            handleViewTeamMembers(state.currentTeamId, document.getElementById('team-members-title').textContent.split(' - ')[0]);
            loadTeams();
        } catch (error) {
            errorEl.textContent = error.message || 'Failed to add member';
            errorEl.classList.remove('hidden');
        }
    });

    // Close modals when clicking backdrop
    document.querySelectorAll('.modal-backdrop').forEach(backdrop => {
        backdrop.addEventListener('click', () => {
            backdrop.closest('.modal').classList.add('hidden');
        });
    });
});
