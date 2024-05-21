import {Controller} from "@hotwired/stimulus"
import {ufw} from "ufw"

// Connects to data-controller="upload-files"
export default class extends Controller {
    connect() {
        var offcanvasTop = document.querySelector('.offcanvas.offcanvas-top');
        offcanvasTop.style.height = '400px'; // 设置自定义的高度

        // 获取选择文件的input元素
        const fileInput = document.getElementById('fileInput');
        // 获取文件列表的ul元素
        const fileList = document.getElementById('fileList');
        // 获取上传按钮
        const uploadBtn = document.getElementById('uploadBtn');
        // 警告框
        const alertPlaceholder = document.getElementById('upload_file_alert')
        const csrf_token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

        fileInputInit();

        // 监听上传按钮的点击事件
        uploadBtn.addEventListener('click', start_upload);

        const alert = (message, type) => {
            const wrapper = document.createElement('div')
            wrapper.innerHTML = [
                `<div class="alert alert-${type} alert-dismissible" role="alert">`,
                `   <div>${message}</div>`,
                '   <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>',
                '</div>'
            ].join('')

            alertPlaceholder.append(wrapper)
        }

        function start_upload() {
            const files = fileInput.files;

            if (files.length !== 0) {
                uploadBtn.disabled = true;
                fileInput.disabled = true;
                notice_unload();


                let finishCount = 0;
                for (let i = 0; i < files.length; i++) {
                    let file = files[i];
                    const listItem = fileList.querySelector(`li[file_name="${file.name}"]`);
                    ufw(file, dir_path, "/upload_file", csrf_token, function (result) {
                        let result_json = JSON.parse(JSON.stringify(result));
                        let stat_code = result_json.data.stat_code;
                        let progress = result_json.data.progress;
                        if (updateListItem(listItem, progress, stat_code)) {
                            finishCount = finishCount + 1;
                        }
                        if (finishCount === files.length) {
                            fileInput.disabled = false;
                            cancel_notice_unload();
                        }
                    })
                }
            }
        }


        function updateListItem(listItem, progress, status) {

            if (progress !== null) {
                let progressBarInner = listItem.querySelector(".progress-bar");
                progressBarInner.style.width = `${progress}%`;
                progressBarInner.textContent = `${progress}%`;
                progressBarInner.setAttribute('aria-valuenow', `${progress}`);
            }

            if (status !== null) {
                let statSpan = listItem.querySelector(".badge");
                if (status === 0) {
                    statSpan.className = "badge text-bg-info"
                    statSpan.textContent = "待上传"
                } else if (status === 1) {
                    statSpan.className = "badge text-bg-warning"
                    statSpan.textContent = "校验中"
                }else if(status === 2){
                    statSpan.className = "badge text-bg-warning"
                    statSpan.textContent = "准备中"
                } else if (status === 3) {
                    statSpan.className = "badge text-bg-warning"
                    statSpan.textContent = "上传中"
                } else if(status === 4 ){
                    statSpan.className = "badge text-bg-primary"
                    statSpan.textContent = "处理中"
                } else if (status === 5) {
                    statSpan.className = "badge text-bg-success"
                    statSpan.textContent = "已完成"
                    return true;
                } else if (status === 6) {
                    statSpan.className = "badge text-bg-danger"
                    statSpan.textContent = "失败了"
                    return true;
                } else {
                    statSpan.className = "badge text-bg-secondary"
                    statSpan.textContent = "未知"
                    return true;
                }
            }
            return false;
        }

        function listFile(e) {
            uploadBtn.disabled = false;

            let max_upload_file_count = 2
            if (e.target.files.length > max_upload_file_count){
                alert(`最多只能同时上传 ${max_upload_file_count} 个文件`, 'warning');
                fileInput.value = "";
                fileList.innerHTML = "";
            }

            // 清空文件列表
            fileList.innerHTML = '';

            // 遍历选择的文件
            for (let i = 0; i < e.target.files.length; i++) {
                const file = e.target.files[i];

                // 创建文件列表项
                const listItem = document.createElement('li');
                listItem.className = 'list-group-item';
                listItem.setAttribute("file_name",file.name)

                // 行
                const rowDiv = document.createElement('div');
                rowDiv.className = "row";

                // 左列,文件名和进度条
                const col11 = document.createElement('div');
                col11.className = "col-11";
                col11.textContent = file.name;

                // 进度条
                const progressBarDiv = document.createElement('div');
                progressBarDiv.className = "progress mt-2"
                const progressBarInner = document.createElement('div');
                progressBarInner.className = 'progress-bar';
                progressBarInner.setAttribute('role', 'progressbar');
                progressBarInner.style.width = '0%';
                progressBarInner.textContent = "0%";
                progressBarInner.setAttribute('aria-valuenow', '0');
                progressBarInner.setAttribute('aria-valuemin', '0');
                progressBarInner.setAttribute('aria-valuemax', '100');
                progressBarDiv.appendChild(progressBarInner);
                col11.appendChild(progressBarDiv);

                // 右列，删除按钮
                const col = document.createElement('div');
                col.className = "col d-flex align-items-center justify-content-center";

                // 状态徽章
                const statSpan = document.createElement("span");
                statSpan.className = "badge text-bg-info";
                statSpan.textContent = "待上传";
                col.appendChild(statSpan);

                rowDiv.appendChild(col11);
                rowDiv.appendChild(col);

                listItem.appendChild(rowDiv)

                // 将文件列表项添加到文件列表
                fileList.appendChild(listItem);
            }
        }

        function fileInputInit() {
            // 监听选择文件按钮的change事件
            fileInput.addEventListener('change', listFile);
        }

        function notice_unload() {
            window.addEventListener('beforeunload', notice_alert);
        }

        function cancel_notice_unload() {
            window.removeEventListener('beforeunload', notice_alert)
        }

        function notice_alert(e) {
            e.preventDefault();
            e.returnValue = '有文件正在上传，确认离开吗？';
        }
    }
}
