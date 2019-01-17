var fs = require('fs');
var path = require('path');
var Mock = require('mockjs');

var apiMap = {
	// '/api/user/init': 'init',
	// '/api/common/timestamp': 'timestamp',
	// '/api/dialog/user/chatting': 'chatList',
	// '/api/dialog/user/closed': 'chatList',
	// '/api/dialog/history': 'history'
};

var getJsonFile = function(filePath) {
	// 读取指定json文件
	var json = fs.readFileSync(path.resolve(__dirname, filePath), 'utf-8');
	// 解析并返回
	// return JSON.parse(json);
	return eval(json);
};

class Tool {
	constructor(app, path) {
		return app.get(path, function(rep, res) {
			// 每次响应请求时读取mock data的json文件
			// util.getJsonFile方法定义了如何读取json文件并解析成数据对象
			var json = getJsonFile(apiMap[path] + '.js');
			// json = getJsonFile('./test.json');
			// 将json传入 Mock.mock 方法中，生成的数据返回给浏览器
			res.json(Mock.mock(json));
		});
	}
}

module.exports = function(app) {
	// 监听 http 请求
	for (var path in apiMap) {
		new Tool(app, path);
	}
}