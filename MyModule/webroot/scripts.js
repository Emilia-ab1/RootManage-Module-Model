// 计数标题点击次数
let titleClickCount = 0;
let titleClickTimer = null;

// 改进标题点击动画并添加多次点击跳转功能
function enhanceTitleAnimation() {
    const mainTitle = document.getElementById('mainTitle');
    if (!mainTitle) return;

    // 确定当前页面和目标页面
    const currentPage = window.location.pathname.split('/').pop();
    let targetPage = '';

    if (currentPage === 'index.html' || currentPage === '') {
        targetPage = 'UniCron.html';
    } else if (currentPage === 'UniCron.html') {
        targetPage = 'index.html';
    } else {
        // 默认目标页面
        targetPage = 'index.html';
    }

    mainTitle.addEventListener('click', () => {
        titleClickCount++;
        // 添加缩放动画
        mainTitle.style.transition = 'transform 0.3s ease';
        mainTitle.style.transform = 'scale(1.08)';
        setTimeout(() => {
            mainTitle.style.transform = 'scale(1)';
        }, 300);

        // 如果在1.5秒内点击次数达到3次，跳转到目标页面
        if (titleClickCount === 3) {
            // 清除计时器
            clearTimeout(titleClickTimer);
            // 执行页面跳转，添加过渡动画
            initiatePageTransition();
            setTimeout(() => {
                window.location.href = targetPage;
            }, 500); // 与过渡动画时间一致
            titleClickCount = 0;
        } else {
            // 重置计数器的计时器
            clearTimeout(titleClickTimer);
            titleClickTimer = setTimeout(() => {
                titleClickCount = 0;
            }, 1500);
        }
    });
}

// 添加页面过渡动画
function initiatePageTransition() {
    const overlay = document.getElementById('transitionOverlay');
    if (overlay) {
        overlay.classList.add('active');
    }
}

// 页面加载后初始化
window.onload = function() {
    document.body.style.opacity = '1';
    initializeInteractions();
    enhanceTitleAnimation();
    // 加载文件内容（仅在 index.html 中需要）
    const currentPage = window.location.pathname.split('/').pop();
    if (currentPage === 'index.html' || currentPage === '') {
        loadFile('root', 'statusContent');
        loadFile('UniCron.log', 'logContent');
    }
    // 其他初始化函数...
};

// 加载文件内容
function loadFile(filePath, elementId) {
    fetch(filePath)
        .then(response => {
            if (!response.ok) {
                throw new Error('网络响应不是OK');
            }
            return response.text();
        })
        .then(data => {
            const element = document.getElementById(elementId);
            if (element) {
                element.textContent = data;
            }
        })
        .catch(error => {
            const element = document.getElementById(elementId);
            if (element) {
                element.textContent = '无法加载文件: ' + error;
            }
        });
}

// 切换暗色模式与亮色模式
document.addEventListener('DOMContentLoaded', () => {
    const toggleModeBtn = document.getElementById('toggleMode');
    if (toggleModeBtn) {
        toggleModeBtn.addEventListener('click', function () {
            document.body.classList.toggle('light-mode');
        });
    }

    // 跳转到GitHub项目（仅在 index.html 中需要）
    const githubBtn = document.getElementById('githubBtn');
    if (githubBtn) {
        githubBtn.addEventListener('click', function () {
            window.open('https://github.com/LIghtJUNction/RootManage-Module-Model', '_blank');
        });
    }

    // 刷新按钮与彩蛋（仅在 index.html 中需要）
    const refreshBtn = document.getElementById('refreshBtn');
    if (refreshBtn) {
        let refreshCount = 0;
        refreshBtn.addEventListener('click', function () {
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

// 彩蛋功能
function triggerEasterEgg() {
    // 实现彩蛋效果的代码
    alert('🎉 彩蛋触发！');
}

// 让元素可拖动并添加果冻效果
function makeDraggable(element) {
    let isDragging = false;
    let startX, startY;
    let offsetX = 0, offsetY = 0;

    // 适配鼠标和触摸事件的坐标获取
    const getEventX = (e) => e.type.includes('touch') ? (e.touches[0] ? e.touches[0].clientX : e.changedTouches[0].clientX) : e.clientX;
    const getEventY = (e) => e.type.includes('touch') ? (e.touches[0] ? e.touches[0].clientY : e.changedTouches[0].clientY) : e.clientY;

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
            // 添加果冻效果
            element.style.transform = 'translate(0px, 0px)';
            element.style.transition = 'transform 0.5s cubic-bezier(0.25, 1.5, 0.5, 1)';
            setTimeout(() => {
                element.style.transition = '';
            }, 500);
            offsetX = 0;
            offsetY = 0;
        }
    };

    // 添加事件监听
    element.addEventListener('mousedown', dragStart);
    element.addEventListener('mousemove', dragMove);
    document.addEventListener('mouseup', dragEnd);

    element.addEventListener('touchstart', dragStart, { passive: false });
    element.addEventListener('touchmove', dragMove, { passive: false });
    document.addEventListener('touchend', dragEnd);
}

// 初始化卡片和按钮的交互
function initializeInteractions() {
    const elements = document.querySelectorAll('.card, .btn-group button');
    elements.forEach(element => {
        // 拖动功能
        makeDraggable(element);
    });
}