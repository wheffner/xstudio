// SPDX-License-Identifier: Apache-2.0
import QtQuick 2.12
import QtQuick.Window 2.15

import xStudio 1.0

import xstudio.qml.module 1.0
import xstudio.qml.viewport 1.0

Item {

    id: shortcuts
    property var playlist_panel: sessionWidget.playlist_panel
    property var viewport: sessionWidget.viewport
    property var playhead: viewport.playhead
    property var selectionFilter: sessionWidget.playerWidget.selectionFilter
    property var source: session.selectedSource
    property var context

    property var topLevelWindow
    property bool shortcutsWithDigits: true

    function toggleViewportChannel(chan_idx) {
        //colourPipeline.channel != chan_idx ? colourPipeline.channel = chan_idx : colourPipeline.channel = 0
    }

    function play_faster(forwards) {
        if (!playhead.playing) {
            playhead.forward = forwards
            playhead.velocityMultiplier = 1
            playhead.playing = true
        } else if (playhead.forward != forwards) {
            playhead.forward = forwards
            playhead.velocityMultiplier = 1
        } else if (playhead.velocityMultiplier < 16) {
            playhead.velocityMultiplier = playhead.velocityMultiplier*2
        }
    }

    // Keys.forwardTo: viewport
    // For now, define shortcuts for controlling playback as I haven't worked
    // out how to capture keystrokes in the whole UI and forwarding to the
    // viewport to handle - that would be a better solution if we can make
    // it work!
    /*XsHotkey {
        context: shortcuts.context
        sequence: ["Space"]
        onActivated: {
            playhead.playing = !playhead.playing
        }
    }*/

    // Other shortcuts ...
    XsHotkey {
        context: shortcuts.context
        sequence: "Escape"
        name: "Toggle controls visible, exists fullscreen"
        description: "Hit this key to show the x-studio controls and/or exit full screen mode"
        onActivated: {
            if (!playerWidget.controlsVisible) {
                playerWidget.toggleControlsVisible()
            } else {
                playerWidget.normalScreen()
            }
        }
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Left"
        name: "Step backwards one frame"
        description: "Halts playback (if playing) and steps playhead back one frame"
        onActivated: {
            if (playhead.playing) {
                playhead.playing = false
            }
            playhead.step(-1)
        }
        autoRepeat: true
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Right"
        name: "Step forwards one frame"
        description: "Halts playback (if playing) and steps playhead forwards one frame"
        onActivated: {
            if (playhead.playing) {
                playhead.playing = false
            }
            playhead.step(1)
        }
        autoRepeat: true
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Up"
        name: "Jump to previous source"
        description: "Cycles current on-screen media backwards through selected media sources"
        onActivated: {
            if (!playhead.jumpToPreviousSource()) {
                if(preferences.cycle_through_playlist.value && source.mediaList[0].uuid == selectionFilter.selectedMediaUuids[0]){
                    selectionFilter.moveSelectionByIndex(source.mediaList.length - 1)
                } else {
                    selectionFilter.moveSelectionByIndex(-1)
                }
            }
        }
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Down"
        name: "Jump to next source"
        description: "Cycles current on-screen media forwards through selected media sources"
        onActivated: {
            if (!playhead.jumpToNextSource()) {
                if(preferences.cycle_through_playlist.value && source.mediaList[source.mediaList.length - 1].uuid == selectionFilter.selectedMediaUuids[0]){
                    selectionFilter.moveSelectionByIndex(-(source.mediaList.length - 1))
                } else {
                    selectionFilter.moveSelectionByIndex(1)
                }
            }
        }
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Ctrl+a"
        name: "Select All"
        description: "Selects all media in the playlist for viewing"
        onActivated: media_list.selectAll()
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Ctrl+d"
        name: "De-select All"
        description: "De-selects all media in the playlist for viewing, then selects the first media item."
        onActivated: media_list.deselectAll()
    }

    XsHotkey {
        context: shortcuts.context
        sequence: "Ctrl+n"
        name: "New Session"
        description: "Create a new session, asks if you want to save current session."
        onActivated: {
          app_window.session.save_before_new_session()
        }
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "."
        name: "Next Bookmark"
        description: "Jump through the timeline to the next bookmarked frame."
        onActivated: playhead.frame = playhead.nextBookmark(playhead.frame)
    }
    XsHotkey {
        context: shortcuts.context
        sequence: ","
        name: "Previous Bookmark"
        description: "Jump through the timeline to the previous bookmarked frame."
        onActivated: playhead.frame = playhead.previousBookmark(playhead.frame)
    }

    XsHotkey {
        context: shortcuts.context
        sequence: "Shift+l"
        name: "Nearest Bookmark"
        description: "Jump through the timeline to the nearest bookmarked frame."
        onActivated: {
            let pos = playhead.getNearestBookmark(playhead.frame)
            if(pos.length) {
                playhead.setLoopStart(pos[0] + playhead.sourceOffsetFrames)
                playhead.setLoopEnd(pos[1] + playhead.sourceOffsetFrames)
                playhead.useLoopRange = true
            }
        }
    }

    XsHotkey {
        context: shortcuts.context
        sequence: ";"
        name: "Create Bookmark Silently"
        description: "Create a new bookmark on the current frame."
        onActivated: {
            let ind = session.bookmarkModel.search(session.add_note(playhead.media.uuid), "uuidRole")
            if(ind.valid) {
                session.bookmarkModel.set(ind, playhead.media.mediaSource.fileName, "subjectRole")
                session.bookmarkModel.set(ind, playhead.mediaSecond, "startRole")
                session.bookmarkModel.set(ind, 0, "durationRole")
            }
        }
    }

    XsHotkey {
        context: shortcuts.context
        sequence: ":"
        name: "Create Bookmark"
        description: "Create a new bookmark on the current frame and pops-up the bookmarks interface."
        onActivated: {
            let ind = session.bookmarkModel.search(session.add_note(playhead.media.uuid), "uuidRole")
            if(ind.valid) {
                session.bookmarkModel.set(ind, playhead.media.mediaSource.fileName, "subjectRole")
                session.bookmarkModel.set(ind, playhead.mediaSecond, "startRole")
                session.bookmarkModel.set(ind, 0, "durationRole")
            }

            sessionWidget.toggleNotes(true)
        }
    }

    XsHotkey {
        context: shortcuts.context
        sequence: "'"
        name: "Extend Bookmark Duration"
        description: "Extend the duration of the nearest bookmark on the timeline so that it reaches to the current frame."
        onActivated: {
            let pos = playhead.getNearestBookmark(playhead.frame)
            if(pos.length) {
                let ind = session.bookmarkModel.search(pos[2], "uuidRole")
                if(ind.valid) {
                    session.bookmarkModel.set(ind, playhead.frame - pos[0], "durationFrameRole")
                }
           }
        }
    }

    // Temp fix to show annotations tool (not strictly keeping it as plugin
    // controlled behaviour)
    XsModuleAttributes {
        id: anno_tool_backend_settings
        attributesGroupName: "annotations_tool_settings"
    }

    XsHotkey {
        context: shortcuts.context
        sequence: "n"
        name: "Show or Hide Notes"
        description: "Either shows and activates or hides the notes (bookmarks) window."
        onActivated: sessionWidget.toggleNotes()
    }

    /*XsHotkey {
        context: shortcuts.context
        sequence: "Shift+p"
        name: "Create New Playlist"
        description: "Creates a new playlist."
        onActivated: XsUtils.openDialog("qrc:/dialogs/XsNewPlaylistDialog.qml",playlist_panel).open()
    }*/

    XsHotkey {
        context: shortcuts.context
        sequence: "Shift+d"
        name: "Create Divider"
        description: "Creates a divider in the session playlist view."
        onActivated: XsUtils.openDialog("qrc:/dialogs/XsNewSessionDividerDialog.qml",playlist_panel).open()
    }

    XsHotkey {
        context: shortcuts.context
        sequence: "Alt+d"
        name: "Create Divider With Date"
        description: "Creates a divider in the session playlist view and titles it with today's date."
        onActivated: {
                let d = XsUtils.openDialog("qrc:/dialogs/XsNewSessionDividerDialog.qml",playlist_panel)
                d.dated = true
                d.open()
        }
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Shift+s"
        name: "Create Subset"
        description: "Creates a playlsit subset under the current playlist."
        onActivated: XsUtils.openDialog("qrc:/dialogs/XsNewSubsetDialog.qml",playlist_panel).open()
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Shift+t"
        name: "Create Timeline"
        description: "Creates a timeline under the current playlist."
        onActivated: XsUtils.openDialog("qrc:/dialogs/XsNewTimelineDialog.qml",playlist_panel).open()
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Shift+c"
        name: "Create Contact Sheet"
        description: "Creates a contact sheet under the current playlist."
        onActivated: XsUtils.openDialog("qrc:/dialogs/XsNewContactSheetDialog.qml",playlist_panel).open()
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Shift+i"
        name: "Create Playlist Divider"
        description: "Creates a divider within the subsets of the current playlist."
        onActivated: XsUtils.openDialog("qrc:/dialogs/XsNewPlaylistDividerDialog.qml",playlist_panel).open()
    }

    XsHotkey {
        context: shortcuts.context
        sequence: "i"
        name: "Set Loop In Point"
        description: "Sets the playhead looping in point at the current frame."
        onActivated: {
            playhead.setLoopStart(playhead.frame)
            playhead.useLoopRange = true
        }
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "o"
        name: "Set Loop Sout Point"
        description: "Sets the playhead looping out point at the current frame."
        onActivated: {
            playhead.setLoopEnd(playhead.frame)
            playhead.useLoopRange = true
        }
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "p"
        name: "Toggle loop in/out range"
        description: "Turns on or turns off the in/out points for looping"
        onActivated: playhead.useLoopRange = !playhead.useLoopRange
    }

    XsHotkey {
        context: shortcuts.context
        sequence: "Ctrl+h"
        name: "Toggle Controls Visible"
        description: "Toggles the main UI controls visible to give minimal interface"
        onActivated: playerWidget.toggleControlsVisible()
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Ctrl+f"
        name: "Toggle Full Screen"
        description: "Toggles the xStudio UI in/out of full-screen mode"
        onActivated: playerWidget.toggleFullscreen()
    }

    /*XsHotkey {
        context: shortcuts.context
        sequence: "Alt+f"
        name: "Toggle Full Screen"
        description: "Toggles the xStudio UI in/out of full-screen mode"
        onActivated: parent_win.fitWindowToImage()
    }*/

    XsHotkey {
        context: shortcuts.context
        sequence: "1"
        name: "View 1st selected source"
        onActivated: playhead.keyPlayheadIndex = 0
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "2"
        name: "View 2nd selected source"
        onActivated: playhead.keyPlayheadIndex = 1
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "3"
        name: "View 3rd selected source"
        onActivated: playhead.keyPlayheadIndex = 2
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "4"
        name: "View 4th selected source"
        onActivated: playhead.keyPlayheadIndex = 3
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "5"
        name: "View 5th selected source"
        onActivated: playhead.keyPlayheadIndex = 4
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "6"
        name: "View 6th selected source"
        onActivated: playhead.keyPlayheadIndex = 5
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "7"
        name: "View 7th selected source"
        onActivated: playhead.keyPlayheadIndex = 6
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "8"
        name: "View 8th selected source"
        onActivated: playhead.keyPlayheadIndex = 7
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "9"
        name: "View 9th selected source"
        onActivated: playhead.keyPlayheadIndex = 8
    }

    XsButtonDialog {
        id: removeMedia
        // parent: sessionWidget.media_list
        text: "Remove Selected Media"
        width: 300
        buttonModel: ["Cancel", "Remove"]
        onSelected: {
            if(button_index == 1) {
                sessionWidget.media_list.delete_selected()
            }
        }
    }

    XsHotkey {
        context: shortcuts.context
        sequence: "Delete"//, "Backspace"
        name: "Remove media"
        description: "Removes current selected media from playlist"
        onActivated: removeMedia.open()
    }

    Repeater {
        model: app_window.session.mediaFlags
        Item {
            XsHotkey {
        context: shortcuts.context
                sequence:  "Ctrl+" + (index == app_window.session.mediaFlags.length-1 ? 0: index+1)
                name: "Flag media with color " + (index == app_window.session.mediaFlags.length-1 ? 0: index+1)
                description: "Flags media with the associated colour code"
                onActivated: app_window.session.flag_selected_media(modelData.colour, modelData.name)


                // onActivated: app_window.session.flag_current_media(
                //     modelData.colour,
                //     modelData.name
                // )
            }
        }
    }

    XsHotkey {
        context: shortcuts.context
        sequence: "F1"
        name: "Show User Docs"
        description: "Loads the xstudio user docs into your default web browser"
        onActivated: {
            var url = session.userDocsUrl()
            if (url == "") {
                errorDialog.text = "Unable to resolve location of user docs."
                errorDialog.visible = true
            } else {
                Qt.openUrlExternally(url)
            }
        }
    }

    XsHotkey {
        context: shortcuts.context
        sequence: "Tab"
        name: "Toggle Presentation Mode"
        description: "Toggles xStudio in/out of presentation mode"
        onActivated: {
            sessionWidget.togglePresentationLayout()
        }
    }

    XsHotkey {
        context: shortcuts.context
        sequence: "Ctrl+s"
        name: "Save Session"
        description: "Saves current session under current file path."
        onActivated: app_window.session.save_session()
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Ctrl+shift+s"
        name: "Save Session As"
        description: "Saves current session under a new file path."
        onActivated: app_window.session.save_session_as()

    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Ctrl+o"
        name: "Open new session"
        description: "Open new session"
        onActivated: app_window.session.save_before_open()
    }

    XsHotkey {
        context: shortcuts.context
        sequence: "Ctrl+/"
        name: "Show about info"
        description: "Shows the xStudio About panel."
        onActivated: openDialog("qrc:/dialogs/XsAboutDialog.qml")
    }
    XsHotkey {
        context: shortcuts.context
        sequence: "Ctrl+Q"
        name: "Quit"
        description: "Quits xStudio."
        onActivated: app_window.close()
    }
    XsHotkey {
        context: shortcuts.context
        sequence:  "Home"
        name: "To Start"
        description: "Jumps to the start frame"
        onActivated: playhead.frame = playhead.useLoopRange ? playhead.loopStart : 0
    }
    XsHotkey {
        context: shortcuts.context
        sequence:  "End"
        name: "To End"
        description: "Jumps to the end frame"
        onActivated: playhead.frame = playhead.useLoopRange ? playhead.loopEnd : playhead.frames-1
    }

    property var thedialog: undefined
    function openDialog(qml_path) {
		var component = Qt.createComponent(qml_path);
		if (component.status == Component.Ready) {
            thedialog = component.createObject(app_window);
            thedialog.visible = true
		} else {
			// Error Handling
			console.log("Error loading component:", component.errorString());
		}
	}


}