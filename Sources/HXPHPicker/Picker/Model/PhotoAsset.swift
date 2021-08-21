//
//  PhotoAsset.swift
//  HXPhotoPickerSwift
//
//  Created by Silence on 2020/11/12.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

public typealias PhotoAssetICloudHandler = (PhotoAsset, PHImageRequestID) -> Void
public typealias PhotoAssetProgressHandler = (PhotoAsset, Double) -> Void
public typealias PhotoAssetFailureHandler = (PhotoAsset, [AnyHashable : Any]?, AssetError) -> Void

open class PhotoAsset: Equatable {
    
    /// 系统相册里的资源
    public var phAsset: PHAsset? { didSet { setMediaType() } }
    
    /// 媒体类型
    public var mediaType: PhotoAsset.MediaType = .photo
    
    /// 媒体子类型
    public var mediaSubType: PhotoAsset.MediaSubType = .image
    
    #if HXPICKER_ENABLE_EDITOR
    /// 图片编辑数据
    public var photoEdit: PhotoEditResult? { didSet { pFileSize = nil } }
    
    /// 视频编辑数据
    public var videoEdit: VideoEditResult? { didSet { pFileSize = nil } }
    
    var initialPhotoEdit: PhotoEditResult?
    var initialVideoEdit: VideoEditResult?
    #endif
    
    /// 原图
    /// 如果为网络图片时，获取的是缩略地址的图片，也可能为nil
    /// 如果为网络视频，则为nil
    public var originalImage: UIImage? { getOriginalImage() }

    /// 图片/视频文件大小
    public var fileSize: Int { getFileSize() }
    
    /// 视频时长 格式：00:00
    public var videoTime: String? {
        get {
            #if HXPICKER_ENABLE_EDITOR
            if let videoEdit = videoEdit {
                return videoEdit.videoTime
            }
            #endif
            return pVideoTime
        }
    }
    
    /// 视频时长 秒
    public var videoDuration: TimeInterval {
        get {
            #if HXPICKER_ENABLE_EDITOR
            if let videoEdit = videoEdit {
                return videoEdit.videoDuration
            }
            #endif
            return pVideoDuration
        }
    }
    
    /// 当前资源是否被选中
    public var isSelected: Bool = false
    
    /// 选中时的下标
    public var selectIndex: Int = 0
    
    /// 图片/视频尺寸大小
    public var imageSize: CGSize { getImageSize() }
    
    /// 是否是 gif
    public var isGifAsset: Bool { mediaSubType.isGif }
    
    /// 是否是本地 Asset
    public var isLocalAsset: Bool { mediaSubType.isLocal }
    
    /// 是否是网络 Asset
    public var isNetworkAsset: Bool { mediaSubType.isNetwork }
    
    /// 根据系统相册里对应的 PHAsset 数据初始化
    /// - Parameter asset: 系统相册里对应的 PHAsset 数据
    public init(asset: PHAsset) {
        self.phAsset = asset
        setMediaType()
    }
    
    /// 根据系统相册里对应的 PHAsset本地唯一标识符 初始化
    /// - Parameter localIdentifier: 系统相册里对应的 PHAsset本地唯一标识符
    public init(localIdentifier: String) {
        phAsset = AssetManager.fetchAsset(withLocalIdentifier: localIdentifier)
        setMediaType()
    }
    
    /// 初始化本地图片
    /// - Parameters:
    ///   - localImageAsset: 对应本地图片的 LocalImageAsset
    public init(localImageAsset: LocalImageAsset) {
        self.localImageAsset = localImageAsset
        mediaType = .photo
        if let imageData = localImageAsset.imageData {
            mediaSubType = imageData.isGif ? .localGifImage : .localImage
        }else if let imageURL = localImageAsset.imageURL {
            mediaSubType = imageURL.isGif ? .localGifImage : .localImage
        }else {
            mediaSubType = .localImage
        }
    }
    
    /// 初始化本地视频
    /// - Parameters:
    ///   - localVideoAsset: 对应本地视频的 LocalVideoAsset
    public init(localVideoAsset: LocalVideoAsset) {
        if localVideoAsset.duration > 0 {
            pVideoTime = PhotoTools.transformVideoDurationToString(duration: localVideoAsset.duration)
            pVideoDuration = localVideoAsset.duration
        }
        self.localVideoAsset = localVideoAsset
        mediaType = .video
        mediaSubType = .localVideo
    }
    /// 本地图片
    public var localImageAsset: LocalImageAsset?
    /// 本地视频
    public var localVideoAsset: LocalVideoAsset?
    
    /// 本地/网络Asset的唯一标识符
    public private(set) lazy var localAssetIdentifier: String = UUID().uuidString
    
    #if canImport(Kingfisher)
    /// 初始化网络图片
    /// - Parameter networkImageAsset: 对应网络图片的 NetworkImageAsset
    public init(networkImageAsset: NetworkImageAsset) {
        self.networkImageAsset = networkImageAsset
        mediaType = .photo
        mediaSubType = .networkImage(networkImageAsset.originalURL.isGif)
    }
    /// 网络图片
    public var networkImageAsset: NetworkImageAsset?
    
    var localImageType: DonwloadURLType = .thumbnail
    #endif
    
    /// 网络视频
    public var networkVideoAsset: NetworkVideoAsset?
    
    /// 初始化网络视频
    /// - Parameter networkVideoAsset: 对应网络视频的 NetworkVideoAsset
    public init(networkVideoAsset: NetworkVideoAsset) {
        self.networkVideoAsset = networkVideoAsset
        mediaType = .video
        mediaSubType = .networkVideo
        if networkVideoAsset.duration > 0 {
            pVideoDuration = networkVideoAsset.duration
            pVideoTime = PhotoTools.transformVideoDurationToString(duration: networkVideoAsset.duration)
        }
    }
    
    /// iCloud下载状态
    public var downloadStatus: DownloadStatus = .unknow
    
    /// iCloud下载进度，如果取消了会记录上次进度
    public var downloadProgress: Double = 0
    
    var localIndex: Int = 0
    private var pFileSize: Int?
    private var pVideoTime: String?
    private var pVideoDuration: TimeInterval = 0
    
    var playerTime: CGFloat = 0
    
    public static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        return lhs.isEqual(rhs)
    }
}
// MARK: 
public extension PhotoAsset {
    
    /// 判断是否是同一个 PhotoAsset 对象
    func isEqual(_ photoAsset: PhotoAsset?) -> Bool {
        if let photoAsset = photoAsset {
            if self === photoAsset {
                return true
            }
            if let localIdentifier = phAsset?.localIdentifier, let phLocalIdentifier = photoAsset.phAsset?.localIdentifier, localIdentifier == phLocalIdentifier {
                return true
            }
            if localAssetIdentifier == photoAsset.localAssetIdentifier {
                return true
            }
            #if canImport(Kingfisher)
            if let networkImageAsset = networkImageAsset, let phNetworkImageAsset = photoAsset.networkImageAsset {
                if networkImageAsset.originalURL == phNetworkImageAsset.originalURL {
                    return true
                }
            }
            #endif
            if let localImageAsset = localImageAsset, let phLocalImageAsset = photoAsset.localImageAsset {
                if let localImage = localImageAsset.image, let phLocalImage = phLocalImageAsset.image, localImage == phLocalImage {
                    return true
                }
                if let localImageURL = localImageAsset.imageURL, let phLocalImageURL = phLocalImageAsset.imageURL, localImageURL == phLocalImageURL {
                    return true
                }
            }
            if let localVideoAsset = localVideoAsset, let phLocalVideoAsset = photoAsset.localVideoAsset {
                if localVideoAsset.videoURL == phLocalVideoAsset.videoURL {
                    return true
                }
            }
            if let networkVideoAsset = networkVideoAsset, let phNetworkVideoAsset = photoAsset.networkVideoAsset {
                if networkVideoAsset.videoURL.absoluteString == phNetworkVideoAsset.videoURL.absoluteString {
                    return true
                }
            }
            if let phAsset = phAsset, phAsset == photoAsset.phAsset {
                return true
            }
        }
        return false
    }
}

// MARK: Self-use
extension PhotoAsset {
     
    func copyCamera() -> PhotoAsset {
        var photoAsset: PhotoAsset
        if mediaType == .photo {
            photoAsset = PhotoAsset.init(localImageAsset: localImageAsset!)
        }else {
            photoAsset = PhotoAsset.init(localVideoAsset: localVideoAsset!)
        }
        photoAsset.localAssetIdentifier = localAssetIdentifier
        photoAsset.localIndex = localIndex
        return photoAsset
    }
    
    func updateVideoDuration(_ duration: TimeInterval) {
        pVideoDuration = duration
        pVideoTime = PhotoTools.transformVideoDurationToString(duration: duration)
    }
    
    func getPFileSize() -> Int? {
        pFileSize
    }
    func updateFileSize(_ fileSize: Int) {
        pFileSize = fileSize
    }
    
    func setMediaType() {
        if phAsset?.mediaType.rawValue == 1 {
            mediaType = .photo
            mediaSubType = .image
        }else if phAsset?.mediaType.rawValue == 2 {
            mediaType = .video
            mediaSubType = .video
            pVideoDuration = phAsset!.duration
            pVideoTime = PhotoTools.transformVideoDurationToString(duration: TimeInterval(round(phAsset!.duration)))
        }
    }
    func getLocalImageData() -> Data? {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit {
            do {
                let imageData = try Data.init(contentsOf: photoEdit.editedImageURL)
                return imageData
            }catch {
            }
            return PhotoTools.getImageData(for: photoEdit.editedImage)
        }
        if let videoEdit = videoEdit {
            return PhotoTools.getImageData(for: videoEdit.coverImage)
        }
        #endif
        if let imageData = localImageAsset?.imageData {
            return imageData
        }
        if let imageURL = localImageAsset?.imageURL {
            do {
                let imageData = try Data.init(contentsOf: imageURL)
                return imageData
            }catch {}
        }
        if mediaType == .photo {
            return PhotoTools.getImageData(for: localImageAsset?.image)
        }else {
            checkLoaclVideoImage()
            return PhotoTools.getImageData(for: localVideoAsset?.image)
        }
    }
    func checkLoaclVideoImage() {
        if localVideoAsset?.image == nil {
            localVideoAsset?.image = PhotoTools.getVideoThumbnailImage(videoURL: localVideoAsset?.videoURL, atTime: 0.1)
        }
    }
    func getLocalVideoDuration(completionHandler: ((TimeInterval, String) -> Void)? = nil) {
        if pVideoDuration > 0 {
            completionHandler?(pVideoDuration, pVideoTime!)
        }else {
            DispatchQueue.global().async {
                let duration = PhotoTools.getVideoDuration(videoURL: self.localVideoAsset?.videoURL)
                self.pVideoDuration = duration
                self.pVideoTime = PhotoTools.transformVideoDurationToString(duration: duration)
                DispatchQueue.main.async {
                    completionHandler?(duration, self.pVideoTime!)
                }
            }
        }
    }
    func getFileSize() -> Int {
        if let fileSize = pFileSize {
            return fileSize
        }
        #if HXPICKER_ENABLE_EDITOR
        if photoEdit != nil {
            if let imageData = getLocalImageData() {
                pFileSize = imageData.count
                return imageData.count
            }
            return 0
        }
        if let videoEdit = videoEdit {
            pFileSize = videoEdit.editedFileSize
            return videoEdit.editedFileSize
        }
        #endif
        var fileSize = 0
        if let photoAsset = phAsset {
            if photoAsset.isImageAnimated && mediaSubType != .imageAnimated {
                if let imageData = PhotoTools.getImageData(for: originalImage) {
                    fileSize = imageData.count
                }
                pFileSize = fileSize
                return fileSize
            }
            let assetResources = PHAssetResource.assetResources(for: photoAsset)
            let assetIsLivePhoto = photoAsset.isLivePhoto
            var livePhotoType: PHAssetResourceType = .photo
            var liveVideoType: PHAssetResourceType = .pairedVideo
            for assetResource in assetResources {
                if assetResource.type == .adjustmentData {
                    livePhotoType = .fullSizePhoto
                    liveVideoType = .fullSizePairedVideo
                    break
                }
            }
            for assetResource in assetResources {
                if assetIsLivePhoto {
                    if mediaSubType != .livePhoto {
                        if assetResource.type == .photo {
                            if let photoFileSize = assetResource.value(forKey: "fileSize") as? Int {
                                fileSize += photoFileSize
                            }
                        }
                    }else {
                        switch assetResource.type {
                        case livePhotoType, liveVideoType:
                            if let photoFileSize = assetResource.value(forKey: "fileSize") as? Int {
                                fileSize += photoFileSize
                            }
                        default:
                            break
                        }
                    }
                }else {
                    if let photoFileSize = assetResource.value(forKey: "fileSize") as? Int {
                        fileSize += photoFileSize
                    }
                }
            }
        }else {
            if self.mediaType == .photo {
                #if canImport(Kingfisher)
                if let networkImageAsset = networkImageAsset, fileSize == 0 {
                    if networkImageAsset.fileSize > 0 {
                        fileSize = networkImageAsset.fileSize
                        pFileSize = fileSize
                    }
                    return fileSize
                }
                #endif
                if let imageData = getLocalImageData() {
                    fileSize = imageData.count
                }
            }else {
                if let videoURL = localVideoAsset?.videoURL {
                    fileSize = videoURL.fileSize
                }else if let networkVideoAsset = networkVideoAsset {
                    if networkVideoAsset.fileSize > 0 {
                        fileSize = networkVideoAsset.fileSize
                    }else {
                        let key = networkVideoAsset.videoURL.absoluteString
                        if PhotoTools.isCached(forVideo: key) {
                            let videoURL = PhotoTools.getVideoCacheURL(for: key)
                            fileSize = videoURL.fileSize
                        }
                    }
                }
            }
        }
        pFileSize = fileSize
        return fileSize
    }
    func requestFileSize(result: @escaping (Int, PhotoAsset) -> Void) {
        DispatchQueue.global().async {
            let fileSize = self.getFileSize()
            DispatchQueue.main.async {
                result(fileSize, self)
            }
        }
    }
    func getOriginalImage() -> UIImage? {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit {
            return UIImage(contentsOfFile: photoEdit.editedImageURL.path)
        }
        if let videoEdit = videoEdit {
            return videoEdit.coverImage
        }
        #endif
        guard let phAsset = phAsset else {
            if mediaType == .photo {
                if let image = localImageAsset?.image {
                    return image
                }else if let imageURL = localImageAsset?.imageURL {
                    let image = UIImage.init(contentsOfFile: imageURL.path)
                    localImageAsset?.image = image
                }
                return localImageAsset?.image
            }else {
                checkLoaclVideoImage()
                return localVideoAsset?.image
            }
        }
        let options = PHImageRequestOptions.init()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        if mediaSubType == .imageAnimated {
            options.version = .original
        }
        var originalImage: UIImage?
        let isGif = phAsset.isImageAnimated
        AssetManager.requestImageData(for: phAsset, options: options) { (result) in
            switch result {
            case .success(let dataResult):
                if isGif && self.mediaSubType != .imageAnimated {
                    let image = UIImage(data: dataResult.imageData)
                    if let data = PhotoTools.getImageData(for: image) {
                        originalImage = UIImage(data: data)
                    }
                }else {
                    originalImage = UIImage.init(data: dataResult.imageData)
                }
            default:
                break
            }
        }
        return originalImage
    }
    func getImageSize() -> CGSize {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit {
            return photoEdit.editedImage.size
        }
        if let videoEdit = videoEdit {
            return videoEdit.coverImage?.size ?? CGSize(width: 200, height: 200)
        }
        #endif
        let size: CGSize
        if let phAsset = phAsset {
            if phAsset.pixelWidth == 0 || phAsset.pixelHeight == 0 {
                size = CGSize(width: 200, height: 200)
            }else {
                size = CGSize(width: phAsset.pixelWidth, height: phAsset.pixelHeight)
            }
        }else {
            if let localImage = localImageAsset?.image {
                size = localImage.size
            }else if let localImageData = localImageAsset?.imageData,
                     let image = UIImage.init(data: localImageData) {
                size = image.size
            }else if let imageURL = localImageAsset?.imageURL,
                     let image = UIImage.init(contentsOfFile: imageURL.path) {
                localImageAsset?.image = image
                size = image.size
            }else if let videoSize = localVideoAsset?.videoSize,
                     !videoSize.equalTo(.zero) {
                size = videoSize
            }else if let localImage = localVideoAsset?.image {
                size = localImage.size
            }else if let networkVideo = networkVideoAsset {
                if !networkVideo.videoSize.equalTo(.zero) {
                    size = networkVideo.videoSize
                }else if let image = networkVideo.coverImage {
                    size = image.size
                }else {
                    let key = networkVideo.videoURL.absoluteString
                    if PhotoTools.isCached(forVideo: key) {
                        let videoURL = PhotoTools.getVideoCacheURL(for: key)
                        if let image = PhotoTools.getVideoThumbnailImage(videoURL: videoURL, atTime: 0.1) {
                            networkVideoAsset?.coverImage = image
                            return image.size
                        }
                    }
                    size = CGSize(width: 200, height: 200)
                }
            }else {
                #if canImport(Kingfisher)
                if let networkImageSize = networkImageAsset?.imageSize, !networkImageSize.equalTo(.zero) {
                    size = networkImageSize
                } else {
                    size = CGSize(width: 200, height: 200)
                }
                #else
                size = CGSize(width: 200, height: 200)
                #endif
            }
        }
        return size
    }
    func requestlocalImageData(resultHandler: ((PhotoAsset, Result<ImageDataResult, AssetManager.ImageDataError>) -> Void)?) {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit {
            do {
                let imageData = try Data.init(contentsOf: photoEdit.editedImageURL)
                resultHandler?(self, .success(.init(imageData: imageData, imageOrientation: photoEdit.editedImage.imageOrientation, info: nil)))
            }catch {
                resultHandler?(self, .failure(.init(info: nil, error: .invalidData)))
            }
            return
        }
        if let videoEdit = videoEdit {
            if let imageData = PhotoTools.getImageData(for: videoEdit.coverImage) {
                resultHandler?(self, .success(.init(imageData: imageData, imageOrientation: videoEdit.coverImage!.imageOrientation, info: nil)))
            }else {
                resultHandler?(self, .failure(.init(info: nil, error: .invalidData)))
            }
            return
        }
        #endif
        if phAsset == nil {
            DispatchQueue.global().async {
                if let imageData = self.localImageAsset?.imageData {
                    let image = UIImage(data: imageData)
                    DispatchQueue.main.async {
                        resultHandler?(self, .success(.init(imageData: imageData, imageOrientation: image!.imageOrientation, info: nil)))
                    }
                    return
                }else if let imageURL = self.localImageAsset?.imageURL {
                    do {
                        let imageData = try Data.init(contentsOf: imageURL)
                        let image = UIImage(data: imageData)
                        DispatchQueue.main.async {
                            resultHandler?(self, .success(.init(imageData: imageData, imageOrientation: image!.imageOrientation, info: nil)))
                        }
                        return
                    }catch { }
                }else if let localImage = self.localImageAsset?.image,
                         let imageData = PhotoTools.getImageData(for: localImage) {
                    DispatchQueue.main.async {
                        resultHandler?(self, .success(.init(imageData: imageData, imageOrientation: localImage.imageOrientation, info: nil)))
                    }
                    return
                }else {
                    if self.isNetworkAsset {
                        #if canImport(Kingfisher)
                        self.getNetworkImage {  (image) in
                            if let imageData = image?.kf.gifRepresentation() {
                                DispatchQueue.main.async {
                                    resultHandler?(self, .success(.init(imageData: imageData, imageOrientation: image!.imageOrientation, info: nil)))
                                }
                                return
                            }
                            if let imageData = PhotoTools.getImageData(for: image) {
                                DispatchQueue.main.async {
                                    resultHandler?(self, .success(.init(imageData: imageData, imageOrientation: image!.imageOrientation, info: nil)))
                                }
                                return
                            }
                        }
                        #endif
                    }
                }
                DispatchQueue.main.async {
                    resultHandler?(self, .failure(.init(info: nil, error: .invalidData)))
                }
            }
        }
    }
    /// 获取本地图片地址
    func requestLocalImageURL(toFile fileURL:URL? = nil, resultHandler: @escaping AssetURLCompletion) {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit {
            if let fileURL = fileURL {
                if PhotoTools.copyFile(at: photoEdit.editedImageURL, to: fileURL) {
                    resultHandler(.success(.init(url: fileURL, urlType: .local, mediaType: .photo)))
                }else {
                    resultHandler(.failure(.fileWriteFailed))
                }
                return
            }
            resultHandler(.success(.init(url: photoEdit.editedImageURL, urlType: .local, mediaType: .photo)))
            return
        }
        #endif
        if let localImageURL = getLocalImageAssetURL() {
            if let fileURL = fileURL {
                if PhotoTools.copyFile(at: localImageURL, to: fileURL) {
                    resultHandler(.success(.init(url: fileURL, urlType: .local, mediaType: .photo)))
                }else {
                    resultHandler(.failure(.fileWriteFailed))
                }
                return
            }
            resultHandler(.success(.init(url: localImageURL, urlType: .local, mediaType: .photo)))
            return
        }
        DispatchQueue.global().async {
            if let imageData = self.getLocalImageData() {
                if let imageURL = PhotoTools.write(toFile: fileURL, imageData: imageData) {
                    DispatchQueue.main.async {
                        resultHandler(.success(.init(url: imageURL, urlType: .local, mediaType: .photo)))
                    }
                }else {
                    DispatchQueue.main.async {
                        resultHandler(.failure(.fileWriteFailed))
                    }
                }
            }else {
                DispatchQueue.main.async {
                    resultHandler(.failure(.invalidData))
                }
            }
        }
    }
    
    /// 获取本地/网络图片
    /// - Parameters:
    ///   - urlType: 网络图片的url类型
    ///   - resultHandler: 获取结果
    func requestLocalImage(urlType: DonwloadURLType = .original, resultHandler: @escaping (UIImage?, PhotoAsset) -> Void) {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit {
            resultHandler(UIImage(contentsOfFile: photoEdit.editedImageURL.path), self)
            return
        }
        if let videoEdit = videoEdit {
            resultHandler(videoEdit.coverImage, self)
            return
        }
        #endif
        if phAsset == nil {
            if mediaType == .photo {
                if let image = localImageAsset?.image {
                    resultHandler(image, self)
                    return
                }
                if isNetworkAsset {
                    #if canImport(Kingfisher)
                    getNetworkImage(urlType: urlType) { (image) in
                        resultHandler(image, self)
                    }
                    #endif
                    return
                }
                DispatchQueue.global().async {
                    if let imageURL = self.localImageAsset?.imageURL, let image = UIImage.init(contentsOfFile: imageURL.path) {
                        self.localImageAsset?.image = image
                        DispatchQueue.main.async {
                            resultHandler(image, self)
                        }
                    }
                }
            }else {
                PhotoTools.getVideoCoverImage(for: self) { (photoAsset, image) in
                    resultHandler(image, photoAsset)
                }
            }
        }
    }
    
    private func getLocalImageAssetURL() -> URL? {
        #if HXPICKER_ENABLE_EDITOR
        if photoEdit == nil {
            return localImageAsset?.imageURL
        }else {
            return nil
        }
        #else
        return localImageAsset?.imageURL
        #endif
    }
    
    /// 获取本地/网络视频地址
    func requestLocalVideoURL(toFile fileURL:URL? = nil,
                              resultHandler: AssetURLCompletion) {
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = videoEdit {
            if let fileURL = fileURL {
                if PhotoTools.copyFile(at: videoEdit.editedURL, to: fileURL) {
                    resultHandler(.success(.init(url: fileURL, urlType: .local, mediaType: .video)))
                }else {
                    resultHandler(.failure(.fileWriteFailed))
                }
                return
            }
            resultHandler(.success(.init(url: videoEdit.editedURL, urlType: .network, mediaType: .video)))
            return
        }
        #endif
        if phAsset == nil {
            if mediaType == .photo {
                resultHandler(.failure(.typeError))
            }else {
                var videoURL: URL? = nil
                if isNetworkAsset {
                    let key = networkVideoAsset!.videoURL.absoluteString
                    if PhotoTools.isCached(forVideo: key) {
                        videoURL = PhotoTools.getVideoCacheURL(for: key)
                    }
                }else {
                    videoURL = localVideoAsset?.videoURL
                }
                if let fileURL = fileURL, let videoURL = videoURL {
                    if PhotoTools.copyFile(at: videoURL, to: fileURL) {
                        resultHandler(.success(.init(url: fileURL, urlType: .local, mediaType: .video)))
                    }else {
                        resultHandler(.failure(.fileWriteFailed))
                    }
                }else {
                    if let videoURL = videoURL {
                        resultHandler(.success(.init(url: videoURL, urlType: .local, mediaType: .video)))
                    }else {
                        if isNetworkAsset {
                            getNetworkVideoURL(resultHandler: resultHandler)
                        }else {
                            resultHandler(.failure(.localURLIsEmpty))
                        }
                    }
                }
            }
        }
    }
    func requestAssetImageURL(toFile fileURL:URL? = nil, filterEditor: Bool = false, resultHandler: @escaping AssetURLCompletion) {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit, !filterEditor {
            if let fileURL = fileURL {
                if PhotoTools.copyFile(at: photoEdit.editedImageURL, to: fileURL) {
                    resultHandler(.success(.init(url: fileURL, urlType: .local, mediaType: .photo)))
                }else {
                    resultHandler(.failure(.fileWriteFailed))
                }
                return
            }
            resultHandler(.success(.init(url: photoEdit.editedImageURL, urlType: .local, mediaType: .photo)))
            return
        }
        if let videoEdit = videoEdit {
            DispatchQueue.global().async {
                if let imageData = PhotoTools.getImageData(for: videoEdit.coverImage) {
                    if let imageURL = PhotoTools.write(toFile: fileURL, imageData: imageData) {
                        DispatchQueue.main.async {
                            resultHandler(.success(.init(url: imageURL, urlType: .local, mediaType: .photo)))
                        }
                    }else {
                        DispatchQueue.main.async {
                            resultHandler(.failure(.fileWriteFailed))
                        }
                    }
                }else {
                    DispatchQueue.main.async {
                        resultHandler(.failure(.invalidData))
                    }
                }
            }
            return
        }
        #endif
        guard let phAsset = phAsset else {
            resultHandler(.failure(.invalidPHAsset))
            return
        }
        if mediaType == .video {
            requestImageData(iCloudHandler: nil, progressHandler: nil) { photoAsset, result in
                switch result {
                case .success(let dataResult):
                    let imageData = dataResult.imageData
                    DispatchQueue.global().async {
                        if let imageURL = PhotoTools.write(toFile: fileURL, imageData: imageData) {
                            DispatchQueue.main.async {
                                resultHandler(.success(.init(url: imageURL, urlType: .local, mediaType: .photo)))
                            }
                        }else {
                            DispatchQueue.main.async {
                                resultHandler(.failure(.fileWriteFailed))
                            }
                        }
                    }
                case .failure(let error):
                    resultHandler(.failure(error.error))
                }
            }
            return
        }
        var imageFileURL: URL
        if let fileURL = fileURL {
            imageFileURL = fileURL
        }else {
            var suffix: String
            if mediaSubType == .imageAnimated {
                suffix = "gif"
            }else {
                suffix = "jpeg"
            }
            imageFileURL = PhotoTools.getTmpURL(for: suffix)
        }
        let isGif = phAsset.isImageAnimated
        AssetManager.requestImageURL(for: phAsset, toFile: imageFileURL) { (result) in
            switch result {
            case .success(let imageURL):
                if isGif && self.mediaSubType != .imageAnimated {
                    // 本质上是gif，需要变成静态图
                    do {
                        let imageData = PhotoTools.getImageData(for: UIImage.init(contentsOfFile: imageURL.path))
                        if FileManager.default.fileExists(atPath: imageURL.path) {
                            try FileManager.default.removeItem(at: imageURL)
                        }
                        try imageData?.write(to: imageURL)
                        resultHandler(.success(.init(url: imageURL, urlType: .local, mediaType: .photo)))
                    } catch {
                        resultHandler(.failure(.fileWriteFailed))
                    }
                }else {
                    resultHandler(.success(.init(url: imageURL, urlType: .local, mediaType: .photo)))
                }
            case .failure(let error):
                resultHandler(.failure(error))
            }
        }
    }
    
    func requestAssetVideoURL(toFile fileURL:URL? = nil,
                              exportPreset: ExportPreset? = nil,
                              videoQuality: Int = 5,
                              exportSession: ((AVAssetExportSession) -> Void)? = nil,
                              resultHandler: @escaping AssetURLCompletion) {
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = videoEdit {
            if let fileURL = fileURL {
                if PhotoTools.copyFile(at: videoEdit.editedURL, to: fileURL) {
                    resultHandler(.success(.init(url: fileURL, urlType: .local, mediaType: .video)))
                }else {
                    resultHandler(.failure(.fileWriteFailed))
                }
                return
            }
            resultHandler(.success(.init(url: videoEdit.editedURL, urlType: .local, mediaType: .video)))
            return
        }
        #endif
        guard let phAsset = phAsset else {
            resultHandler(.failure(.invalidPHAsset))
            return
        }
        let toFile = fileURL == nil ? PhotoTools.getVideoTmpURL() : fileURL!
        if let exportPreset = exportPreset {
            AssetManager.exportVideoURL(
                forVideo: phAsset,
                toFile: toFile,
                exportPreset: exportPreset,
                videoQuality: videoQuality,
                exportSession: exportSession)
            { (result) in
                switch result {
                case .success(let videoURL):
                    resultHandler(.success(.init(url: videoURL, urlType: .local, mediaType: .video)))
                case .failure(let error):
                    resultHandler(.failure(error.error))
                }
            }
            return
        }
        if mediaSubType == .livePhoto {
            let assetHandler: (URL?, Error?) -> Void  =  { videoURL, error in
                if let videoURL = videoURL {
                    resultHandler(.success(.init(url: videoURL, urlType: .local, mediaType: .video)))
                }else {
                    resultHandler(.failure(.exportFailed(error)))
                }
            }
            AssetManager.requestLivePhoto(videoURL: phAsset, toFile: toFile) { (videoURL, error) in
                assetHandler(videoURL, nil)
            }
        }else {
            if mediaType == .photo {
                resultHandler(.failure(.typeError))
                return
            }
            AssetManager.requestVideoURL(for: phAsset, toFile: toFile) { (result) in
                switch result {
                case .success(let videoURL):
                    resultHandler(.success(.init(url: videoURL, urlType: .local, mediaType: .video)))
                case .failure(let error):
                    resultHandler(.failure(error))
                }
            }
        }
    }
}
