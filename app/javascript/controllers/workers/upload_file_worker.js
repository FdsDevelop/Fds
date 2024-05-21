
importScripts("../../libs/spark-md5.min.js")

self.onmessage = async function (event) {
    const file_data = event.data.file_data;
    const dir_path = event.data.dir_path;
    const url = event.data.url;
    const csrf_token = event.data.csrf_token;

    //console.log(`dir_path = ${dir_path}, url = ${url}`)
    // 执行计算密集型的操作
    try {
        let result = await start_file_upload(file_data, dir_path, url, csrf_token);
    } catch (e) {
        //console.log(e)
        self.postMessage({ret_code: -1, err_msg: e.message, data: {stat_code: 6, progress: null}});
    }

};


async function start_file_upload(file, dir_path, url, csrf_token) {
    return new Promise(async (resolve, reject) => {
        try {
            let start_time = new Date().getTime();
            await file_validate(file, dir_path);
            let end_time = new Date().getTime();
            let elapsed_time = end_time - start_time;
            //console.log(`验证耗时: ${elapsed_time}ms -- (${elapsed_time/1000}s)`)

            start_time = new Date().getTime();
            let prepare_res = await file_prepar(file, dir_path);
            end_time = new Date().getTime();
            elapsed_time = end_time - start_time;
            //console.log(`准备耗时: ${elapsed_time} ms -- (${elapsed_time/1000}s)`)

            start_time = new Date().getTime();
            let hash = prepare_res["data"];
            await upload_file(file, hash, dir_path, url, 2 * 1024 * 1024, csrf_token);
            end_time = new Date().getTime();
            elapsed_time = end_time - start_time;
            //console.log(`上传耗时: ${elapsed_time} ms -- (${elapsed_time/1000}s)`)
            resolve({ret_code: 0, err_msg: "", data: null});
        } catch (e) {
            reject(e);
        }
    })
}

function file_validate(file, dir_path) {
    return new Promise((resolve, reject) => {
        //console.log("文件校验阶段")
        self.postMessage({ret_code: 0, err_msg: "", data: {stat_code: 1, progress: 0}});
        resolve({ret_code: 0, err_msg: "", data: null})
    })
}

async function file_prepar(file, dir_path) {
    return new Promise(async (resolve, reject) => {
        //console.log("文件准备阶段")
        self.postMessage({ret_code: 0, err_msg: "", data: {stat_code: 2, progress: 0}});
        try {
            let hash_result = await calculateFileHash(file);
            let hash = hash_result["data"];
            resolve({ret_code: 0, err_msg: "", data: hash});
        } catch (e) {
            reject(e)
        }
    })
}

async function upload_file(file, file_md5, dir_path, url, chip_size, csrf_token) {
    return new Promise(async (resolve, reject) => {
        //console.log("文件上传阶段")
        self.postMessage({ret_code: 0, err_msg: "", data: {stat_code: 3, progress: 0}});
        let file_size = file.size;
        let chip_count = Math.ceil(file_size / chip_size);
        try {
            await start_file_upload();
            let succes_chip_count = 0;
            for (let i = 0; i < chip_count; i++) {
                let prepare_result = await prepare_chip(i);
                let form = await prepare_result["data"];
                await upload_chip(form);
                //console.log(`${file.name} 上传进度： ${i + 1}/${chip_count}`);
                let persent = Math.round((succes_chip_count/chip_count)*100);
                self.postMessage({ret_code: 0, err_msg: "", data: {stat_code: 3, progress: persent}});
                succes_chip_count = succes_chip_count + 1;
                if (succes_chip_count === chip_count) {
                    self.postMessage({ret_code: 0, err_msg: "", data: {stat_code: 4, progress: 100}});
                    await end_file_upload()
                    self.postMessage({ret_code: 0, err_msg: "", data: {stat_code: 5, progress: 100}});
                    //console.log("文件传输完成");
                    resolve({ret_code: 0, err_msg: "", data: null})
                }
            }
        } catch (e) {
            reject(e)
        }
    })

    function start_file_upload() {
        return new Promise(async (resolve, reject) => {
            let file_size = file.size;
            let chip_count = Math.ceil(file_size / chip_size);

            let start_form = new FormData();
            start_form.append("opt_flag", 0);
            start_form.append("dir_path", dir_path);
            start_form.append("file_md5", file_md5);
            start_form.append("file_name", file.name);
            start_form.append("file_size", file_size);
            start_form.append("chip_count", chip_count);
            try {
                let result = await file_operation_request(start_form, url, csrf_token);
                //console.log(`${file.name} 开始上传`);
                resolve(result)
            } catch (e) {
                reject(e)
            }
        })
    }

    async function prepare_chip(i) {
        return new Promise(async (resolve, reject) => {
            let file_size = file.size;
            let chip_count = Math.ceil(file_size / chip_size);

            let form = new FormData();
            form.append("opt_flag", 1);
            form.append("dir_path", dir_path);
            form.append("file_md5", file_md5);
            form.append("file_name", file.name);
            form.append("file_size", file_size);
            form.append("chip_count", chip_count);
            form.append("chip_index", i);
            let start_pos = i * chip_size;
            let end_pos = Math.min(file_size, start_pos + chip_size);
            let chip_data = file.slice(start_pos, end_pos);
            form.append("chip_data", chip_data);
            form.append("chip_size", (end_pos - start_pos));
            try {
                let hash_result = await calculateFileHash(chip_data);
                let hash = hash_result["data"];
                form.append("chip_md5", hash);
                resolve({ret_code: 0, err_msg: "", data: form})
            } catch (e) {
                reject({ret_code: -1, err_msg: "无法计算切片 MD5", data: null})
            }
        })
    }

    function upload_chip(form) {
        return new Promise(async (resolve, reject) => {
            try {
                let result = await file_operation_request(form, url, csrf_token);
                resolve(result)
            } catch (e) {
                reject(e)
            }
        })
    }

    function end_file_upload() {
        return new Promise(async (resolve, reject) => {
            let file_size = file.size;
            let chip_count = Math.ceil(file_size / chip_size);

            let end_form = new FormData();
            end_form.append("opt_flag", 2);
            end_form.append("dir_path", dir_path);
            end_form.append("file_md5", file_md5);
            end_form.append("file_name", file.name);
            end_form.append("file_size", file_size);
            end_form.append("chip_count", chip_count);
            try {
                let result = await file_operation_request(end_form, url, csrf_token);
                //console.log(`${file.name} 保存完成`);
                resolve(result)
            } catch (e) {
                reject(e)
            }
        })
    }

}

function file_operation_request(form_data, url, csrf_token) {
    return new Promise((resolve, reject) => {
        fetch(url, {
            method: "post",
            headers: {
                'X-CSRF-Token': csrf_token
            },
            body: form_data
        }).then(response => {
            if (response.ok) {
                return response.json();
            } else {
                throw new Error("请求失败");
            }
        }).then(data => {
            // //console.log(`response data = ${JSON.stringify(data)}`);
            if (data === null || data["ret_code"] !== 0){
                reject(data)
            }else{
                resolve(data);
            }
        }).catch(error => {
            //console.log(`response error = ${error}`);
            reject({ret_code: -1, err_msg: error.message, data: null});
        });

    })
}


function calculateFileHash(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();

        reader.onload = (event) => {
            const fileData = event.target.result;
            const spark = new SparkMD5.ArrayBuffer();
            spark.append(fileData);
            const hash = spark.end();
            //console.log(`hash result = ${hash}`)
            resolve({ret_code: 0, err_msg: "", data: hash})
        };

        reader.onerror = (event) => {
            //console.log(event.target.error)
            reject({ret_code: -1, err_msg: "MD5 计算失败", data: null})
        };

        reader.readAsArrayBuffer(file);
    })
}
