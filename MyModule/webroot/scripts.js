let titleClickCount = 0;
let titleClickTimer = null;

function enhanceTitleAnimation() {
    const mainTitle = document.getElementById('mainTitle');
    if (!mainTitle) return;

    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    const targetPage = currentPage === 'index.html' ? 'UniCron.html' : 'index.html';

    mainTitle.addEventListener('click', () => {
        titleClickCount++;
        mainTitle.style.transition = 'transform 0.3s ease';
        mainTitle.style.transform = 'scale(1.08)';
        setTimeout(() => {
            mainTitle.style.transform = 'scale(1)';
        }, 300);

        if (titleClickCount === 3) {
            clearTimeout(titleClickTimer);
            initiatePageTransition();
            setTimeout(() => {
                window.location.href = targetPage;
            }, 500);
            titleClickCount = 0;
        } else {
            clearTimeout(titleClickTimer);
            titleClickTimer = setTimeout(() => {
                titleClickCount = 0;
            }, 1500);
        }
    });
}

function initiatePageTransition() {
    const overlay = document.getElementById('transitionOverlay');
    if (overlay) {
        overlay.classList.add('active');
    }
}

window.onload = () => {
    document.body.style.opacity = '1';
    initializeInteractions();
    enhanceTitleAnimation();
    loadModuleProp(); // 加载 module.prop

    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    if (currentPage === 'index.html') {
        loadFile('root', 'statusContent');
        loadFile('UniCron.log', 'logContent');
    }
};

// 优化 loadFile 函数以处理 module.prop
function loadFile(filePath, elementId) {
    fetch(filePath)
        .then(response => {
            if (!response.ok) throw new Error('网络响应不是OK');
            return response.text();
        })
        .then(data => {
            const element = document.getElementById(elementId);
            if (!element) return;

            if (filePath.endsWith('.prop')) {
                const props = parseProp(data);
                displayModuleProps(props);
            } else {
                element.textContent = data;
            }
        })
        .catch(error => {
            const element = document.getElementById(elementId);
            if (element) element.textContent = `无法加载文件: ${error.message}`;
        });
}

// 解析 module.prop 文件
function parseProp(data) {
    const props = {};
    const lines = data.split('\n');
    lines.forEach(line => {
        const [key, value] = line.split('=');
        if (key && value) {
            props[key.trim()] = value.trim();
        }
    });
    return props;
}

// 显示 module.prop 数据
function displayModuleProps(props) {
    const moduleInfo = document.getElementById('moduleInfo');
    if (!moduleInfo) return;

    // 清空已有内容
    moduleInfo.innerHTML = '';

    // 显示模块信息
    for (const [key, value] of Object.entries(props)) {
        const infoElement = document.createElement('p');
        infoElement.textContent = `${key}: ${value}`;
        moduleInfo.appendChild(infoElement);
    }

    // 创建固定卡片
    createFixedCards(moduleInfo);
}

// 创建固定的卡片
function createFixedCards(container) {
    // 添加加入QQ群按钮
    const joinQQButton = document.createElement('button');
    joinQQButton.textContent = '加入QQ群';
    joinQQButton.onclick = () => {
        window.open('http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=JUQAgmzVKn1Oiy0DIgUANuJ03ywH2uB3&authKey=nvZ6SsNP3c76E3iQVpbmVJ3dteHRJlVz%2FwDPiLyiBpQmU%2B9P0Szv7tO3%2FcIOJz%2Bu&noverify=0&group_code=885986098', '_blank');
    };
    const qqButtonContainer = document.createElement('div');
    qqButtonContainer.className = 'fixed-card';
    qqButtonContainer.appendChild(joinQQButton);
    container.appendChild(qqButtonContainer);

    // 添加关注作者链接 - CoolAPK
    const followAuthor_coolapk = document.createElement('a');
    followAuthor_coolapk.href = 'http://www.coolapk.com/u/17845477';
    followAuthor_coolapk.textContent = '关注作者：酷安@LIghtJUNction';
    followAuthor_coolapk.target = '_blank';
    const followAuthorCard_coolapk = document.createElement('div');
    followAuthorCard_coolapk.className = 'fixed-card';
    followAuthorCard_coolapk.appendChild(followAuthor_coolapk);
    container.appendChild(followAuthorCard_coolapk);

    // 添加关注作者链接 - GitHub
    const followAuthor_github = document.createElement('a');
    followAuthor_github.href = 'https://github.com/LIghtJUNction';
    followAuthor_github.textContent = '我的 GitHub@LIghtJUNction';
    followAuthor_github.target = '_blank';
    const followAuthorCard_github = document.createElement('div');
    followAuthorCard_github.className = 'fixed-card';
    followAuthorCard_github.appendChild(followAuthor_github);
    container.appendChild(followAuthorCard_github);
}

document.addEventListener('DOMContentLoaded', () => {
    const cards = document.querySelectorAll('.card');
    const modalOverlay = document.getElementById('modalOverlay');
    const modalTitle = document.getElementById('modalTitle');
    const modalBody = document.getElementById('modalBody');
    const closeModal = document.getElementById('closeModal');
    const transitionOverlay = document.getElementById('transitionOverlay');

    cards.forEach(card => {
        card.addEventListener('click', () => {
            const type = card.dataset.type;
            const content = card.querySelector('pre').innerText;
            modalTitle.textContent = type === 'status' ? '模块状态' : '日志';
            modalBody.textContent = content;

            modalOverlay.classList.add('show');
            transitionOverlay.style.display = 'block';
            transitionOverlay.classList.add('active');
        });

        // 处理触摸事件以支持移动端
        card.addEventListener('touchstart', () => {
            card.classList.add('active');
        });

        card.addEventListener('touchend', () => {
            card.classList.remove('active');
        });
    });

    closeModal.addEventListener('click', () => {
        closeModalFunction();
    });

    modalOverlay.addEventListener('click', (e) => {
        if (e.target === modalOverlay) closeModalFunction();
    });

    function closeModalFunction() {
        modalOverlay.classList.remove('show');
        transitionOverlay.classList.remove('active');
        setTimeout(() => {
            transitionOverlay.style.display = 'none';
        }, 500);
    }
});

document.addEventListener('DOMContentLoaded', () => {
    const toggleModeBtn = document.getElementById('toggleMode');
    if (toggleModeBtn) {
        toggleModeBtn.addEventListener('click', () => {
            document.body.classList.toggle('light-mode');
        });
    }

    const githubBtn = document.getElementById('githubBtn');
    if (githubBtn) {
        githubBtn.addEventListener('click', () => {
            window.open('https://github.com/LIghtJUNction/RootManage-Module-Model', '_blank');
        });
    }

    const refreshBtn = document.getElementById('refreshBtn');
    if (refreshBtn) {
        let refreshCount = 0;
        refreshBtn.addEventListener('click', () => {
            loadFile('root', 'statusContent');
            loadFile('UniCron.log', 'logContent');
            refreshCount++;
            if (refreshCount >= 5) {
                triggerEasterEgg();
                refreshCount = 0;
            }
        });
    }
});

function triggerEasterEgg() {
    alert('🎉 彩蛋触发！');
}

function makeDraggable(element) {
    let isDragging = false;
    let startX, startY;
    let offsetX = 0, offsetY = 0;

    const getEventX = (e) => e.type.includes('touch') ? (e.touches[0]?.clientX || e.changedTouches[0].clientX) : e.clientX;
    const getEventY = (e) => e.type.includes('touch') ? (e.touches[0]?.clientY || e.changedTouches[0].clientY) : e.clientY;

    const dragStart = (e) => {
        isDragging = true;
        startX = getEventX(e) - offsetX;
        startY = getEventY(e) - offsetY;
        element.classList.add('dragging');
        e.preventDefault();
    };

    const dragMove = (e) => {
        if (isDragging) {
            offsetX = getEventX(e) - startX;
            offsetY = getEventY(e) - startY;
            element.style.transform = `translate(${offsetX}px, ${offsetY}px) scale(1.05)`;
        }
    };

    const dragEnd = () => {
        if (isDragging) {
            isDragging = false;
            element.classList.remove('dragging');
            element.style.transform = 'translate(0px, 0px)';
            element.style.transition = 'transform 0.5s cubic-bezier(0.25, 1.5, 0.5, 1)';
            setTimeout(() => {
                element.style.transition = '';
            }, 500);
            offsetX = 0;
            offsetY = 0;
        }
    };

    element.addEventListener('mousedown', dragStart);
    element.addEventListener('mousemove', dragMove);
    document.addEventListener('mouseup', dragEnd);

    element.addEventListener('touchstart', dragStart, { passive: false });
    element.addEventListener('touchmove', dragMove, { passive: false });
    document.addEventListener('touchend', dragEnd);
}

function initializeInteractions() {
    const elements = document.querySelectorAll('.card');
    elements.forEach(element => {
        makeDraggable(element);
    });
}

// 加载 module.prop 并提取数据
function loadModuleProp() {
    loadFile('module.prop', 'moduleInfo');
}