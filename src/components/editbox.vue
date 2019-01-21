<template lang="pug">
.edit-box(
	v-html="innerText"
	@focus="isLocked = 1"
	@blur="isLocked = 0"
	@keydown.enter.exact="$event.preventDefault()"
	@keyup.enter.exact="eventSend"
	@input="textChanged"
	spellcheck="false"
)
</template>
<script lang="coffee">
export default
	name: 'editBox'

	props:
		value:
			type: String
			default: ''
		eventSend:
			type: Function
			default: ->
		eventFocus:
			type: Function
			default: ->
		eventBlur:
			type: Function
			default: ->

	data: ->
		innerText: this.value
		isLocked: 0

	watch:
		value: ->
			this.innerText = this.value or ' ' unless @isLocked

	methods:
		textChanged: -> @$emit 'textChanged', this.$el.innerHTML
</script>
<style lang="sass">
.edit-box
	width: 100%
	height: 100%
	overflow: auto
	word-break: break-all
	outline: none
	user-select: text
	white-space: pre-wrap
	text-align: left
	&[contenteditable=true]
		user-modify: read-write-plaintext-only
	&:empty:before
		content: attr(placeholder)
		display: block
		color: #ccc
</style>