离线安装步骤：

##（本地环境准备离线安装包）  
1. 下载辅助工具：

   ```
   https://github.com/rivernetio/tools
   https://github.com/rivernetio/ansible-ecp
   ```

2. 准备依赖文件：  
   运行脚本下载所需的镜像。（需要有外网的机器，安装了docker）

   ```
   mkdir depends && cd depends
   // 拷贝第一步tools中的prepare_offline_deps.sh脚本到当前目录下
   ./prepare_offline_deps.sh
   cd ..
   tar -czvf depends.tar.gz depends
   ```
 
##（部署环境安装离线安装包）  
1. 拷贝ansible-ecp和depends.tar.gz到部署机，
   修改ansible-ecp/group_vars/all.yml中的参数：
 
   ```
   src_image_tars_dir: "/vagrant/image_tars"  值为放depends解压后的目录
   src_rpms_dir: "/vagrant/rpms/"   值为depends下的ecp-rpm目录
   ecp_local_charts_repo: /home/vagrant/charts/repo/ 值为depends下的ecp-charts目录
   ```

2. 配置机器间免秘钥登录（所有机器，可以参考ansible-ecp/scripts/pre-install.sh）

3. 安装ansible： 

   ```
   cd depends/
   rpm -ivh ansible/*.rpm
   ```

4. 安装docker(所有机器)：

   ```
   cd depends/
   rpm -ivh docker/*.rpm
   // 添加harbor仓库地址
   // 修改 /etc/sysconfig/docker 文件
   // 添加 --insecure-registry=registry.harbor:5000 到 OPTIONS 配置中
   service docker start
   ```

5. 安装ecp：

   ```
   cd ansible-ecp/
   // inventory,添加机器信息
   ansible-playbook -v install.yml
   ```

6. 验证系统是否正确安装：

   ```
   浏览器访问：  IP:31081
   登录用户名：  admin
   登录密码：   password
   ```
   