//
//  PhotoPreviewViewController+Editor.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit

#if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
// MARK: PhotoEditorViewControllerDelegate
extension PhotoPreviewViewController: PhotoEditorViewControllerDelegate {
    public func photoEditorViewController(_ photoEditorViewController: PhotoEditorViewController, didFinish result: PhotoEditResult) {
        let photoAsset = photoEditorViewController.photoAsset!
        photoAsset.photoEdit = result
        if isExternalPreview {
            replacePhotoAsset(at: currentPreviewIndex, with: photoAsset)
        }else {
            if (videoLoadSingleCell && photoAsset.mediaType == .video) || !isMultipleSelect {
                if pickerController!.canSelectAsset(for: photoAsset, showHUD: true) {
                    pickerController?.singleFinishCallback(for: photoAsset)
                }
                return
            }
            reloadCell(for: photoAsset)
            if !photoAsset.isSelected {
                didSelectBoxControlClick()
            }
        }
        delegate?.previewViewController(self, editAssetFinished: photoAsset)
        pickerController?.didEditAsset(photoAsset: photoAsset, atIndex: currentPreviewIndex)
    }
    public func photoEditorViewController(didFinishWithUnedited photoEditorViewController: PhotoEditorViewController) {
        let photoAsset = photoEditorViewController.photoAsset!
        let beforeHasEdit = photoAsset.photoEdit != nil
        photoAsset.photoEdit = nil;
        if beforeHasEdit {
            pickerController?.didEditAsset(photoAsset: photoAsset, atIndex: currentPreviewIndex)
        }
        if !isMultipleSelect {
            if pickerController!.canSelectAsset(for: photoAsset, showHUD: true) {
                pickerController?.singleFinishCallback(for: photoAsset)
            }
            return
        }
        if !photoAsset.isSelected {
            didSelectBoxControlClick()
        }
        if beforeHasEdit {
            reloadCell(for: photoAsset)
        }
        delegate?.previewViewController(self, editAssetFinished: photoAsset)
    }
    public func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        loadTitleChartlet response: @escaping ([EditorChartlet]) -> Void) {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            #if canImport(Kingfisher)
            let titles = PhotoTools.defaultTitleChartlet()
            response(titles)
            #else
            response([])
            #endif
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            loadTitleChartlet: photoEditorViewController,
            response: response
        )
    }
    public func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping (Int, [EditorChartlet]) -> Void) {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            #if canImport(Kingfisher)
            let chartletList = PhotoTools.defaultNetworkChartlet()
            response(titleIndex, chartletList)
            #else
            response(titleIndex, [])
            #endif
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            loadChartletList: photoEditorViewController,
            titleChartlet: titleChartlet,
            titleIndex: titleIndex,
            response: response
        )
    }
    public func photoEditorViewController(didCancel photoEditorViewController: PhotoEditorViewController) {
        
    }
}
// MARK: VideoEditorViewControllerDelegate
extension PhotoPreviewViewController: VideoEditorViewControllerDelegate {
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse)
    {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            #if canImport(Kingfisher)
            let titles = PhotoTools.defaultTitleChartlet()
            response(titles)
            #else
            response([])
            #endif
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            loadTitleChartlet: videoEditorViewController,
            response: response
        )
    }
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping EditorChartletListResponse)
    {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            #if canImport(Kingfisher)
            let chartletList = PhotoTools.defaultNetworkChartlet()
            response(titleIndex, chartletList)
            #else
            response(titleIndex, [])
            #endif
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            loadChartletList: videoEditorViewController,
            titleChartlet: titleChartlet,
            titleIndex: titleIndex,
            response: response
        )
    }
    public func videoEditorViewController(shouldClickMusicTool videoEditorViewController: VideoEditorViewController) -> Bool {
        if let pickerController = pickerController,
           let shouldClick = pickerController.pickerDelegate?.pickerController(pickerController, videoEditorShouldClickMusicTool: videoEditorViewController) {
            return shouldClick
        }
        return true
    }
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void) -> Bool {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            completionHandler(PhotoTools.defaultMusicInfos())
            return false
        }
        return pickerDelegate.pickerController(
            pickerController,
            videoEditor: videoEditorViewController,
            loadMusic: completionHandler
        )
    }
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        didSearch text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void) {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            completionHandler([], false)
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            videoEditor: videoEditorViewController,
            didSearch: text,
            completionHandler: completionHandler
        )
    }
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadMore text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void) {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            completionHandler([], false)
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            videoEditor: videoEditorViewController,
            loadMore: text,
            completionHandler: completionHandler
        )
    }
    public func videoEditorViewController(_ videoEditorViewController: VideoEditorViewController, didFinish result: VideoEditResult) {
        let photoAsset = videoEditorViewController.photoAsset!
        photoAsset.videoEdit = result
        if isExternalPreview {
            replacePhotoAsset(at: currentPreviewIndex, with: photoAsset)
        }else {
            if videoLoadSingleCell || !isMultipleSelect {
                if pickerController!.canSelectAsset(for: photoAsset, showHUD: true) {
                    pickerController?.singleFinishCallback(for: photoAsset)
                }
                return
            }
            reloadCell(for: photoAsset)
            if !photoAsset.isSelected {
                didSelectBoxControlClick()
            }
        }
        delegate?.previewViewController(self, editAssetFinished: photoAsset)
        pickerController?.didEditAsset(photoAsset: photoAsset, atIndex: currentPreviewIndex)
    }
    public func videoEditorViewController(didFinishWithUnedited videoEditorViewController: VideoEditorViewController) {
        let photoAsset = videoEditorViewController.photoAsset!
        let beforeHasEdit = photoAsset.videoEdit != nil
        photoAsset.videoEdit = nil;
        if beforeHasEdit {
            pickerController?.didEditAsset(photoAsset: photoAsset, atIndex: currentPreviewIndex)
        }
        if videoLoadSingleCell || !isMultipleSelect {
            if pickerController!.canSelectAsset(for: photoAsset, showHUD: true) {
                pickerController?.singleFinishCallback(for: photoAsset)
            }
            return
        }
        if beforeHasEdit {
            reloadCell(for: photoAsset)
        }
        if !photoAsset.isSelected {
            didSelectBoxControlClick()
        }
        delegate?.previewViewController(self, editAssetFinished: photoAsset)
    }
    public func videoEditorViewController(didCancel videoEditorViewController: VideoEditorViewController) {
        
    }
}
#endif
