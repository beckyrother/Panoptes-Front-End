React = require 'react'
{Markdown} = (require 'markdownz').default
GenericTask = require '../generic'
TextTaskEditor = require './editor'
levenshtein = require 'fast-levenshtein'

NOOP = Function.prototype

Summary = React.createClass
  displayName: 'TextSummary'

  getDefaultProps: ->
    task: null
    annotation: null
    expanded: false

  render: ->
    <div>
      <div className="question">
        {@props.task.instruction}
      </div>
      <div className="answers">
      {if @props.annotation.value?
        <div className="answer">
          “<code>{@props.annotation.value}</code>”
        </div>}
      </div>
    </div>

module.exports = React.createClass
  displayName: 'TextTask'

  statics:
    Editor: TextTaskEditor
    Summary: Summary

    getDefaultTask: ->
      type: 'text'
      instruction: 'Enter an instruction.'
      help: ''

    getTaskText: (task) ->
      task.instruction

    getDefaultAnnotation: ->
      value: ''

    isAnnotationComplete: (task, annotation) ->
      annotation.value isnt '' or not task.required

    testAnnotationQuality: (unknown, knownGood) ->
      distance = levenshtein.get unknown.value.toLowerCase(), knownGood.value.toLowerCase()
      length = Math.max unknown.value.length, knownGood.value.length
      (length - distance) / length

  getDefaultProps: ->
    task: null
    annotation: null
    onChange: NOOP

  getInitialState: ->
    textareaHeight: undefined
    initOffsetHeight: undefined

  componentDidMount: ->
    @setState initOffsetHeight: @refs.textInput.offsetHeight

  setTagSelection: (e) ->
    textTag = e.target.value
    startTag = '[' + textTag + ']'
    endTag = '[/' + textTag + ']'
    textArea = this.refs.textInput
    textAreaValue = textArea.value
    selectionStart = textArea.selectionStart
    selectionEnd = textArea.selectionEnd
    textBefore = textAreaValue.substring(0, selectionStart)
    if selectionStart is selectionEnd
      textAfter = textAreaValue.substring(selectionStart, textAreaValue.length)
      value = textBefore + startTag + endTag + textAfter
    else
      textInBetween = textAreaValue.substring(selectionStart, selectionEnd)
      textAfter = textAreaValue.substring(selectionEnd, textAreaValue.length)
      value = textBefore + startTag + textInBetween + endTag + textAfter
    newAnnotation = Object.assign @props.annotation, {value}
    @props.onChange newAnnotation

  handleClear: (e) ->
    if e.which is 8 or e.which is 46
      @setState textareaHeight: @state.initOffsetHeight

  updateHeight: ->
    @setState textareaHeight: @refs.textInput.scrollHeight + 2

  render: ->
    <GenericTask question={@props.task.instruction} help={@props.task.help} required={@props.task.required}>
      <label className="answer">
        <textarea
          autoFocus={@props.autoFocus}
          className="standard-input full"
          ref="textInput"
          value={@props.annotation.value}
          onChange={@handleChange}
          rows="1"
          style={height: @state.textareaHeight}
          onKeyDown={@handleClear}
        />
      </label>
      {if @props.task.text_tags
        <div className="transcription-metadata-tags">
          {for tag, i in @props.task.text_tags
            <input type="button" className="standard-button text-tag" key={i} value={tag} onClick={@setTagSelection} />}
        </div>}
    </GenericTask>

  handleChange: ->
    value = @refs.textInput.value

    if @props.annotation.value?.length > value.length
      @setState textareaHeight: @state.initOffsetHeight, =>
        @updateHeight()
    else
      @updateHeight()

    newAnnotation = Object.assign @props.annotation, {value}
    @props.onChange newAnnotation
