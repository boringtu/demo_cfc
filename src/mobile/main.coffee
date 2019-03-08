import '@babel/polyfill'
import Vue from 'vue'
import App from './App.vue'
import axios from 'axios'
import VueAxios from 'vue-axios'
import ALPHA from '@/assets/scripts/alpha'
import Utils from '@/assets/scripts/utils'
import Velocity from 'velocity-animate'
import 'velocity-animate/velocity.ui'
import SockJS from 'sockjs-client'
import Stomp from 'stompjs'

Vue.use VueAxios, axios

Vue.config.productionTip = false

window.SockJS = SockJS
window.Stomp = Stomp

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