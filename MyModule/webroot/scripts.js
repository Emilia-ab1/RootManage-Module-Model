// 页面加载动画
window.onload = function() {
    document.body.style.opacity = '1';
    animateTitle();
    initializeCards();
};

// 动画标题
function animateTitle() {
    const title = document.querySelector('h1');
    const letters = title.textContent.split('');
    title.textContent = '';
    letters.forEach((letter, index) => {
        const span = document.createElement('span');
        span.textContent = letter;
        span.style.opacity = '0';
        span.style.display = 'inline-block';
        span.style.transform = 'translateY(-20px)';
        span.style.transition = `opacity 0.3s ease ${index * 0.05}s, transform 0.3s ease ${index * 0.05}s`;
        title.appendChild(span);
        setTimeout(() => {
            span.style.opacity = '1';
            span.style.transform = 'translateY(0)';
        }, 100);
    });
}

// 加载文件内容
function loadFile(filePath, elementId) {
    fetch(filePath)
        .then(response => response.text())
        .then(data => {
            document.getElementById(elementId).textContent = data;
        })
        .catch(error => {
            document.getElementById(elementId).textContent = '无法加载文件: ' + error;
        });
}

// 加载模块状态与日志文件
loadFile('root', 'statusContent');
loadFile('UniCron.log', 'logContent');

// 切换暗色模式与亮色模式
const toggleModeBtn = document.getElementById('toggleMode');
toggleModeBtn.addEventListener('click', function () {
    document.body.classList.toggle('light-mode');
    let isLightMode = document.body.classList.contains('light-mode');
    this.textContent = isLightMode ? '☀️' : '🌚';
});

// 跳转到GitHub项目
document.getElementById('githubBtn').addEventListener('click', function () {
    window.open('https://github.com/LIghtJUNction/RootManage-Module-Model/releases', '_blank');
});

// 刷新按钮与彩蛋
let refreshCount = 0;
document.getElementById('refreshBtn').addEventListener('click', function () {
    loadFile('status', 'statusContent');
    loadFile('log', 'logContent');

    refreshCount++;
    if (refreshCount >= 5) {
        triggerEasterEgg();
        refreshCount = 0;
    }
});

// 彩蛋功能
function triggerEasterEgg() {
    const container = document.querySelector('.container');
    const fireworks = document.createElement('div');
    fireworks.classList.add('fireworks');
    container.appendChild(fireworks);

    setTimeout(() => {
        container.removeChild(fireworks);
    }, 3000);
}

// 动态创建烟花效果
const style = document.createElement('style');
style.innerHTML = `
.fireworks {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    pointer-events: none;
    overflow: hidden;
}

.fireworks::after {
    content: '';
    position: absolute;
    width: 100%;
    height: 100%;
    background: url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAwIiBoZWlnaHQ9IjYwMCIgdmlld0JveD0iMCAwIDYwMCA2MDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgPHBhdGggZD0iTTMwMCAwTDMxMCA2MCAyMDAgNjAwQzIwMCA2MDAgMzAwIDYwMCAzMDAgNjAwQzMwMCA2MDAgNjAwIDEwMDAgNjAwIDEwMDBIMzAwQzMwMCAxMDAwIDMwMCA2MDAgMzAwIDYwMEwzMDAgMDBaIiBmaWxsPSJub25lIiBzdHJva2U9IiNmZmYiIHN0cm9rZS13aWR0aD0iMiIvPgo8L3N2Zz4K');
    animation: explode 3s ease-out forwards;
}

@keyframes explode {
    0% { opacity: 1; transform: scale(0.5); }
    100% { opacity: 0; transform: scale(3); }
}
`;
document.head.appendChild(style);

// 初始化卡片交互
function initializeCards() {
    const cards = document.querySelectorAll('.card');

    cards.forEach(card => {
        // 点击震动
        card.addEventListener('click', () => {
            triggerShake(card);
        });

        // 拖动功能
        makeDraggable(card);

        // 拉伸功能
        makeResizable(card);
    });
}

// 震动动画
function triggerShake(card) {
    card.classList.add('shake');
    setTimeout(() => {
        card.classList.remove('shake');
    }, 500);
}

// 拖动功能实现，自动归位
function makeDraggable(element) {
    let isDragging = false;
    let startX, startY;
    let originalX = 0;
    let originalY = 0;

    element.addEventListener('mousedown', (e) => {
        isDragging = true;
        startX = e.clientX;
        startY = e.clientY;
        originalX = 0;
        originalY = 0;
        element.classList.add('snap-back');
        e.preventDefault();
    });

    document.addEventListener('mousemove', (e) => {
        if (isDragging) {
            const dx = e.clientX - startX;
            const dy = e.clientY - startY;
            element.style.transform = `translate(${dx}px, ${dy}px)`;
        }
    });

    document.addEventListener('mouseup', () => {
        if (isDragging) {
            isDragging = false;
            element.style.transform = `translate(0px, 0px)`;
        }
    });
}

// 拉伸功能实现
function makeResizable(element) {
    const resizer = document.createElement('div');
    resizer.classList.add('resizer');
    element.appendChild(resizer);

    let isResizing = false;
    let startX, startY, startWidth, startHeight;

    resizer.addEventListener('mousedown', (e) => {
        isResizing = true;
        startX = e.clientX;
        startY = e.clientY;
        const rect = element.getBoundingClientRect();
        startWidth = rect.width;
        startHeight = rect.height;
        document.body.style.cursor = 'nwse-resize';
        e.preventDefault();
        e.stopPropagation();
    });

    document.addEventListener('mousemove', (e) => {
        if (isResizing) {
            const dx = e.clientX - startX;
            const dy = e.clientY - startY;
            element.style.width = `${startWidth + dx}px`;
            element.style.height = `${startHeight + dy}px`;
        }
    });

    document.addEventListener('mouseup', () => {
        if (isResizing) {
            isResizing = false;
            document.body.style.cursor = 'default';
        }
    });
}


// 标题点击跳转逻辑
const mainTitle = document.getElementById('mainTitle');
let clickCount = 0;
const requiredClicks = 5;
const resetTime = 2000; // 2秒内连续点击

let clickTimer = null;

mainTitle.addEventListener('click', () => {
    // 添加动画类
    mainTitle.classList.add('animate');
    setTimeout(() => {
        mainTitle.classList.remove('animate');
    }, 500);

    clickCount++;
    if (clickCount === 1) {
        clickTimer = setTimeout(() => {
            clickCount = 0;
        }, resetTime);
    }

    if (clickCount >= requiredClicks) {
        clearTimeout(clickTimer);
        clickCount = 0;
        initiateTransition();
    }
});

function initiateTransition() {
    const overlay = document.getElementById('transitionOverlay');
    overlay.classList.add('active');
    setTimeout(() => {
        window.location.href = 'game.html';
    }, 500); // 与CSS中的transition时间一致
}