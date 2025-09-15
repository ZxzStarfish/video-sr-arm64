# 在Windows系统下将项目上传到GitHub

本指南将帮助您在Windows系统下将视频超分辨率项目上传到GitHub。

## 前提条件

1. 已安装Git for Windows
2. 已拥有GitHub账号
3. 已完成项目开发

## 步骤一：安装Git for Windows

如果您尚未安装Git，请按照以下步骤安装：

1. 访问[Git官网下载页面](https://git-scm.com/download/win)
2. 下载适合您Windows系统的版本（通常选择64-bit Git for Windows Setup）
3. 运行安装程序，按照默认选项完成安装
4. 安装完成后，可以通过`Win+R`输入`cmd`打开命令提示符，输入`git --version`验证安装是否成功

## 步骤二：配置Git用户信息

首次使用Git时，需要配置您的用户名和邮箱地址（与GitHub账号关联）：

1. 打开命令提示符（cmd）
2. 运行以下命令：

```bash
git config --global user.name "您的GitHub用户名"
git config --global user.email "您的GitHub邮箱地址"
```

## 步骤三：创建GitHub仓库

1. 登录您的GitHub账号
2. 点击页面右上角的`+`号，选择`New repository`
3. 填写仓库信息：
   - **Repository name**: 输入仓库名称（例如：video-sr-arm64）
   - **Description**: 输入仓库描述（可选）
   - **Visibility**: 选择仓库可见性（Public或Private）
   - 不要勾选`Initialize this repository with a README`
4. 点击`Create repository`按钮创建仓库
5. 创建成功后，复制页面上显示的仓库URL（HTTPS或SSH格式）

## 步骤四：初始化本地Git仓库

1. 打开命令提示符（cmd）
2. 使用`cd`命令导航到您的项目目录：

```bash
cd d:\HuaweiMoveData\Users\starfish\OneDrive\桌面\test\test_torch
```

3. 初始化Git仓库：

```bash
git init
```

4. 将所有文件添加到暂存区：

```bash
git add .
```

5. 提交更改：

```bash
git commit -m "Initial commit"
```

## 步骤五：关联远程GitHub仓库

1. 运行以下命令关联远程仓库（替换为您的仓库URL）：

```bash
git remote add origin https://github.com/您的用户名/仓库名称.git
```

2. 验证远程仓库关联是否成功：

```bash
git remote -v
```

## 步骤六：推送到GitHub

1. 将本地提交推送到GitHub远程仓库：

```bash
git push -u origin master
```

如果使用的是main分支（GitHub默认）：

```bash
git push -u origin main
```

2. 首次推送时，系统会提示您输入GitHub用户名和密码（或个人访问令牌）

> **注意**：从2021年8月起，GitHub不再支持使用密码进行远程操作。请使用[个人访问令牌（PAT）](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)代替密码。

## 步骤七：验证上传结果

1. 返回GitHub网页上的仓库页面
2. 刷新页面，您应该能看到项目文件已成功上传

## 常见问题解决方案

### 1. 推送失败提示"fatal: refusing to merge unrelated histories"

如果远程仓库已有内容（例如README.md），而本地仓库是全新初始化的，可能会出现此错误。解决方案：

```bash
git pull origin master --allow-unrelated-histories
git push -u origin master
```

### 2. 忘记GitHub密码或需要使用个人访问令牌

1. 登录GitHub，点击右上角头像，选择`Settings`
2. 在左侧菜单中选择`Developer settings` -> `Personal access tokens` -> `Tokens (classic)`
3. 点击`Generate new token`按钮
4. 填写token描述，选择适当的权限（对于推送代码，至少需要`repo`权限）
5. 生成后复制token（注意：此token仅显示一次）
6. 在命令行推送时，使用此token作为密码

### 3. 大文件上传问题

如果项目中包含较大的模型文件（.pth），可能会遇到GitHub文件大小限制（超过100MB）。我们已在.gitignore中排除了这些大文件，但如果您确实需要上传，请考虑使用Git LFS（Git Large File Storage）。

## 后续操作建议

1. **保护敏感信息**：确保不要将密码、API密钥等敏感信息上传到GitHub
2. **定期备份**：定期推送代码以保持备份
3. **分支管理**：对于功能开发，可以创建单独的分支，完成后再合并到主分支
4. **README维护**：保持README.md文件更新，记录项目的最新状态和使用方法

完成以上步骤后，您的视频超分辨率项目就成功上传到GitHub了！