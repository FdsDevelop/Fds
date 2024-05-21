export function ufw(file,dir_path,url,csrf_token,callback) {
    const worker = new Worker(new URL("upload_file_worker", import.meta.url));

    // 接收来自 Web Worker 的消息
    worker.onmessage = function (event) {
        const result = event.data;
        callback(result);
    };
    // 向 Web Worker 发送消息
    worker.postMessage({file_data: file, dir_path: dir_path, url: url, csrf_token: csrf_token});
}