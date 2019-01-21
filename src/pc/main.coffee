import '@babel/polyfill'
import Vue from 'vue'
import App from './App.vue'
import axios from 'axios'
import VueAxios from 'vue-axios'
import { EmojiPickerPlugin } from 'vue-emoji-picker'
import twemoji from 'twemoji'
import ALPHA from '@/assets/scripts/alpha'
import Utils from '@/assets/scripts/utils'
import Velocity from 'velocity-animate'
import 'velocity-animate/velocity.ui'
import SockJS from 'sockjs-client'
import Stomp from 'stompjs'
# import ElementUI from 'element-ui'
import {
	Input
	Button
	Notification
} from 'element-ui'

import 'element-ui/lib/theme-chalk/index.css'

Vue.use EmojiPickerPlugin
Vue.use VueAxios, axios
# Vue.use ElementUI
Vue.use Input
Vue.use Button

Vue.prototype.$notify = Notification

Vue.config.productionTip = false

window.SockJS = SockJS
window.Stomp = Stomp
window.twemoji = twemoji

# 响应拦截器
axiosInterceptor = axios.interceptors.response.use (res) ->
	data = res.data
	if data.state
		# 如果响应 CODE 非 0 时，强制进入 reject
		axios.interceptors.response.handlers[axiosInterceptor].rejected res
	else
		data
, (err) ->
	Promise.reject err

window.vm = new Vue {
	beforeCreate: ->
		Utils.ajax = Utils.ajax.bind @
	render: (h) => h App
}
.$mount '#app'