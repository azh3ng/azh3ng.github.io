---
layout: article
title: Proxmox VE 9.1.1 屏蔽订阅弹窗提示
date: 2025-12-17
tags: [PVE, Proxmox, Linux, 虚拟化]
---

Proxmox VE (PVE) 是一款优秀的开源虚拟化管理平台，基于 Debian 并集成了 KVM 和 LXC 虚拟化技术。然而，在使用社区版时，每次登录 Web 管理界面都会弹出订阅提示窗口，虽然不影响功能使用，但频繁出现确实会影响使用体验。

本文将介绍如何在 Proxmox VE 9.1.1 版本中屏蔽这个登录后的订阅提示弹窗。

## 操作步骤

### 1. 备份原始文件

在进行任何修改之前，强烈建议先备份原始的 JavaScript 文件，以便在出现问题时能够快速恢复：

```bash
cp /usr/share/pve-manager/js/pvemanagerlib.js \
   /usr/share/pve-manager/js/pvemanagerlib.js.bak
```

这条命令会在同目录下创建一个 `.bak` 后缀的备份文件。

### 2. 修改订阅检查代码

使用 `sed` 命令直接修改 JavaScript 文件中的订阅检查逻辑：

```bash
sed -i \
's/Proxmox.Utils.checked_command(Ext.emptyFn);/Ext.emptyFn();\/\* subscription check disabled \*\//g' \
/usr/share/pve-manager/js/pvemanagerlib.js
```

这条命令的作用是将订阅检查函数替换为一个空函数，从而跳过弹窗提示。修改后的代码会添加注释 `/* subscription check disabled */` 以便识别。

### 3. 重启 Web 服务

修改完成后，需要重启 PVE 的 Web 代理服务使更改生效：

```bash
systemctl restart pveproxy
```

等待服务重启完成后，清除浏览器缓存（或使用 Ctrl+F5 强制刷新），重新登录 Proxmox VE 管理界面，订阅提示窗口将不再出现。

## 注意事项

1. **系统更新影响**：当 Proxmox VE 进行系统更新时，`pve-manager` 包可能会被更新，导致修改被覆盖。此时需要重新执行上述步骤。

2. **版本兼容性**：本方法适用于 Proxmox VE 9.1.1 版本，其他版本的文件路径或代码结构可能有所不同，请根据实际情况调整。

3. **官方订阅支持**：如果你在生产环境中使用 Proxmox VE，建议购买官方订阅以获得企业级支持和稳定的更新源。

4. **恢复方法**：如果修改后出现异常，可以使用以下命令恢复原始文件：
   ```bash
   cp /usr/share/pve-manager/js/pvemanagerlib.js.bak \
      /usr/share/pve-manager/js/pvemanagerlib.js
   systemctl restart pveproxy
   ```
