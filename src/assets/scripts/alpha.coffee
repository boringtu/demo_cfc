###
 # 项目配置文件
###
export default do ->
	'use strict'

	### 私有函数 ###


	### ALPHA 命名空间 ###
	window.ALPHA = {}
	Object.defineProperties window.ALPHA,
		# 枚举: 接口地址
		API_PATH:
			writable: off, value:
				## WebSocket ##
				WS: {}
				## 通用 ##
				common:
					# 服务器时间戳
					timestamp: '/api/common/timestamp'
					# 上传文件
					upload: '/api/common/upload'
					# 获取配置
					conf: '/api/common/conf'
				user:
					# 用户初始化数据
					init: '/api/user/init'
					# 立即咨询
					new: '/api/user/new'
					# 历史消息记录
					history: '/api/user/history'

		# PERMISSIONS:
		# 	writable: off, value:
		# 		## 访客对话 ##
		# 		dialogue:
		# 			# 查看客户信息
		# 			# 修改客户信息
		# 		## 内部协同 ##
		# 		synergy:
		# 			# 查看客服列表
		# 			# 添加分组
		# 			# 添加客服
		# 		## 配置管理 ##
		# 		configManagement:
		# 			# 查看风格设置
		# 			# 修改风格设置


		PROTOCOL:
			writable: off, value: location.protocol
		HOSTNAME:
			writable: off, value: location.hostname
		PORT:
			writable: off, value: location.port
		WS_PROTOCOL:
			writable: off, value: /^https/.test(location.protocol) ? 'wss' : 'ws'
		API_HOST:
			writable: off, value: '172.16.10.122:8090'

	Object.defineProperties window.ALPHA.API_PATH.WS,
		# 用于建立 WebSocket 连接
		url:
			writable: off, value: '/api/chat'
		# 枚举：发送 ws 数据的类型
		SEND_CODE:
			writable: off, value:
				# 发送消息
				MESSAGE: 1
		# 枚举：接收 ws 数据的类型
		RECEIVE_CODE:
			writable: off, value:
				p2p:
					# 推送消息
					MESSAGE: 1
					# 排队系统 前面排的人数
					QUEUENUM: 4
					# 会话已结束
					CLOSED: 5
		## 以下用于用以建立的 ws 监听和发送
		# 点对点
		p2p:
			get: -> "/user/#{ ALPHA.userId }/c/chatting"
		# 发送
		send:
			writable: off, value: '/c/chatting'
	
	window.ALPHA