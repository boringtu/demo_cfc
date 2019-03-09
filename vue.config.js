module.exports = {
	pages: {
		pc: {
			entry: 'src/pc/main',
			template: 'public/pc.html',
			filename: 'pc.html'
		},
		mobile: {
			entry: 'src/mobile/main',
			template: 'public/mobile.html',
			filename: 'mobile.html'
		}
	},
	devServer: {
		before: require('./mock'),
		port: 8881,
		proxy: {
			'^/api': {
				target: 'http://172.16.10.122:8090',
				// target: 'http://172.16.10.135:8090',
				pathRewrite: {'^/api': ''},
				changeOrigin: true,
				secure: false,
				ws: true
			},
			'^/upload': {
				target: 'http://172.16.10.122',
				changeOrigin: true,
				secure: false
			}
		}
	},
	configureWebpack: {
		output: {
			publicPath: (function() {
				for (var item of process.argv) {
					if (/--PROD/.test(item)) return 'http://cdn.xx/';
				}
				return '/';
			})()
		},
		// entry: {
		// 	app: './src/main'
		// },
		resolve: {
			extensions: ['.js', '.vue', '.json', '.coffee', '.pug', '.sass', '.scss']
		},
		module: {
			rules: [
				{
					test: /\.(coffee)$/,
					use: [{
						loader: 'coffee-loader'
					}]
				},
			]
		},
		externals: {
			'vue': 'Vue',
			'vue-router': 'VueRouter'
		},
		// plugins: [
		// 	new HtmlWebpackPlugin(),
		// 	new WebpackCdnPlugin({
		// 		modules: [
		// 			{
		// 				name: 'vue',
		// 				var: 'Vue',
		// 				path: 'dist/libs/vue.min.js'
		// 			}, {
		// 				name: 'vue-router',
		// 				var: 'VueRouter',
		// 				path: 'dist/libs/vue-router.min.js'
		// 			}, {
		// 				name: 'vuex',
		// 				var: 'Vuex',
		// 				path: 'dist/libs/vuex.min.js'
		// 			}
		// 		],
		// 		publicPath: '/node_modules'
		// 	})
		// ]
	}
};
