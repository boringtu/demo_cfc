###
 # 项目配置文件
###
export default do ->
	'use strict'

	### 私有函数 ###


	### ALPHA 命名空间 ###
	window.ALPHA = {}
	Object.defineProperties window.ALPHA,
		initAttrs:
			writable: off, value:
				name:
					maxlength: 16
				phone:
					maxlength: 11
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

		twemoji:
			writable: off, value:
				params:
					base: '/'
					folder: 'images/twemoji'
					ext: '.png'
				list: [
					'1F600', '1F601', '1F602', '1F603', '1F604'
					'1F605', '1F606', '1F607', '1F608', '1F609'
					'1F60A', '1F60B', '1F60C', '1F60D', '1F60E'
					'1F60F', '1F610', '1F611', '1F612', '1F613'
					'1F614', '1F615', '1F616', '1F617', '1F618'
					'1F619', '1F61A', '1F61B', '1F61C', '1F61D'
					'1F61E', '1F61F', '1F620', '1F621', '1F622'
					'1F623', '1F624', '1F625', '1F626', '1F627'
					'1F628', '1F629', '1F62A', '1F62B', '1F62C'
					'1F62D', '1F62E', '1F62F', '1F630', '1F631'
					'1F632', '1F633', '1F634', '1F635', '1F636'
					'1F637', '1F638', '1F639', '1F63A', '1F63B'
					'1F63C', '1F63D', '1F63E', '1F63F', '1F640'
					'1F641', '1F642', '1F643', '1F644', '1F910'
					'1F911', '1F912', '1F913', '1F914', '1F915'
					'1F916', '1F917', '1F920', '1F921', '1F922'
					'1F923', '1F924', '1F925', '1F927', '1F928'
					'1F929', '1F92A', '1F92B', '1F92C', '1F92D'
					'1F92E', '1F92F', '1F970', '1F973', '1F974'
					'1F975', '1F976', '1F97A', '1F9D0', '2639'
					'263A', '2620', '2622', '2623', '2626'
					'262A', '262E', '262F', '2638', '2648'
					'2649', '264A', '264B', '264C', '264D'
					'264E', '264F', '2650', '2651', '2652'
					'2653', '269b', '26ce', '2695', '2640'
					'2642', '265F', '2660', '2663', '2665'
					'2666', '2668', '267B', '267F', '26A0'
					'26A1', '26AB', '26AA', '2B1B', '2B1C'
					'2B50', '2B55', '3030', '303D'

				]

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
