document.addEventListener('DOMContentLoaded', () => {
    // 主菜单元素
    const mainMenu = document.getElementById('mainMenu');
    const startGameButton = document.getElementById('startGameButton');
    const showInstructionsButton = document.getElementById('showInstructionsButton');

    // 游戏说明元素
    const instructionsScreen = document.getElementById('instructionsScreen');
    const backToMenuButton = document.getElementById('backToMenuButton');

    // 游戏容器
    const gameContainer = document.getElementById('gameContainer');

    // 游戏状态变量
    let score = 0;
    let health = 100;
    let resources = 100;
    let enemyInterval;
    let level = 1;
    let enemiesPerLevel = 5;
    let enemiesSpawned = 0;

    const scoreElement = document.getElementById('score');
    const healthElement = document.getElementById('health');
    const resourcesElement = document.getElementById('resources');
    const levelElement = document.getElementById('level');
    const defenseDeploymentArea = document.getElementById('defenseDeploymentArea');
    const enemyAttackArea = document.getElementById('enemyAttackArea');
    const notificationArea = document.getElementById('notificationArea');
    const gameOverScreen = document.getElementById('gameOverScreen');
    const finalScoreElement = document.getElementById('finalScore');
    const restartButton = document.getElementById('restartButton');
    const exitButton = document.getElementById('exitButton');

    startGameButton.addEventListener('click', startGame);
    showInstructionsButton.addEventListener('click', showInstructions);
    backToMenuButton.addEventListener('click', showMainMenu);
    restartButton.addEventListener('click', initializeGame);
    exitButton.addEventListener('click', () => {
        // 退出游戏逻辑
        showMainMenu();
    });

    function updateInfo() {
        scoreElement.textContent = `分数: ${score}`;
        healthElement.textContent = `生命值: ${health}`;
        resourcesElement.textContent = `资源: ${resources}`;
        levelElement.textContent = `关卡: ${level}`;
    }

    // 显示主菜单
    function showMainMenu() {
        mainMenu.style.display = 'block';
        instructionsScreen.style.display = 'none';
        gameContainer.style.display = 'none';
    }

    // 显示游戏说明
    function showInstructions() {
        mainMenu.style.display = 'none';
        instructionsScreen.style.display = 'block';
        gameContainer.style.display = 'none';
    }

    // 开始游戏
    function startGame() {
        mainMenu.style.display = 'none';
        instructionsScreen.style.display = 'none';
        gameContainer.style.display = 'block';
        initializeGame();
    }

    // 初始化游戏
    function initializeGame() {
        score = 0;
        health = 100;
        resources = 100;
        level = 1;
        enemiesPerLevel = 5;
        enemiesSpawned = 0;
        updateInfo();
        enemyInterval = setInterval(spawnEnemy, 2000 - (level * 200));
    }

    // 防御脚本拖拽功能
    const defenseCards = document.querySelectorAll('.defenseCard');
    defenseCards.forEach(card => {
        card.addEventListener('dragstart', dragStart);
    });

    function dragStart(e) {
        e.dataTransfer.setData('text/plain', e.target.dataset.type);
    }

    defenseDeploymentArea.addEventListener('dragover', e => {
        e.preventDefault();
    });

    defenseDeploymentArea.addEventListener('drop', e => {
        e.preventDefault();
        const type = e.dataTransfer.getData('text/plain');
        const x = e.clientX - defenseDeploymentArea.getBoundingClientRect().left;
        const y = e.clientY - defenseDeploymentArea.getBoundingClientRect().top;
        deployDefense(type, x, y);
    });

    function deployDefense(type, x, y) {
        if (resources < getCost(type)) {
            showNotification('资源不足！');
            return;
        }
        resources -= getCost(type);
        updateInfo();
        const defense = document.createElement('div');
        defense.classList.add('defense');
        defense.classList.add(type);
        defense.style.left = `${x}px`;
        defense.style.top = `${y}px`;
        defenseDeploymentArea.appendChild(defense);
    }

    function getCost(type) {
        switch(type) {
            case 'monitorCron': return 20;
            case 'autoRestart': return 30;
            case 'firewall': return 50;
            default: return 0;
        }
    }

    function getDefenseName(type) {
        switch(type) {
            case 'monitorCron': return '监控Cron';
            case 'autoRestart': return '自动重启';
            case 'firewall': return '防火墙';
            default: return '未知防御';
        }
    }

    // 生成不同类型的敌人
    function spawnEnemy() {
        if (enemiesSpawned >= enemiesPerLevel) {
            clearInterval(enemyInterval);
            setTimeout(nextLevel, 5000); // 等待5秒后进入下一关
            return;
        }
        let enemyType = getRandomEnemyType();
        const enemy = document.createElement('div');
        enemy.classList.add('enemy', enemyType);
        enemy.style.left = '0px';
        enemy.style.top = `${Math.random() * (enemyAttackArea.clientHeight - 60)}px`;
        enemy.dataset.type = enemyType;
        enemy.dataset.health = getEnemyHealth(enemyType);
        enemyAttackArea.appendChild(enemy);
        enemiesSpawned++;
        moveEnemy(enemy);
    }

    function getRandomEnemyType() {
        const types = ['grunt', 'elite', 'boss'];
        return types[Math.floor(Math.random() * types.length)];
    }

    function getEnemyHealth(type) {
        switch(type) {
            case 'grunt': return 50;
            case 'elite': return 100;
            case 'boss': return 200;
            default: return 50;
        }
    }

    function moveEnemy(enemy) {
        let speed;
        switch(enemy.dataset.type) {
            case 'grunt': speed = 1; break;
            case 'elite': speed = 2; break;
            case 'boss': speed = 0.5; break;
            default: speed = 1;
        }
        const moveInterval = setInterval(() => {
            let currentLeft = parseFloat(enemy.style.left);
            enemy.style.left = `${currentLeft + speed}px`;
            if (currentLeft + speed > enemyAttackArea.clientWidth - enemy.clientWidth) {
                clearInterval(moveInterval);
                enemy.remove();
                health -= 10;
                updateInfo();
                checkGameOver();
            }
        }, 20);
    }

    function nextLevel() {
        level++;
        enemiesPerLevel += 3;
        enemiesSpawned = 0;
        enemyInterval = setInterval(spawnEnemy, Math.max(500, 2000 - (level * 200))); // 增加难度，减少生成间隔
        showNotification(`进入第 ${level} 关`);
    }

    function showNotification(message) {
        const notification = document.createElement('div');
        notification.classList.add('notification');
        notification.textContent = message;
        notificationArea.appendChild(notification);
        setTimeout(() => {
            notification.remove();
        }, 3000);
    }

    // 检查游戏是否结束
    function checkGameOver() {
        if (health <= 0) {
            endGame();
        }
    }

    // 结束游戏
    function endGame() {
        clearInterval(enemyInterval);
        gameOverScreen.style.display = 'block';
        finalScoreElement.textContent = score;
    }
});