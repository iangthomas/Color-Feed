//
//  videoCell.swift
//
//  Created by Ian Thomas
//

import UIKit

import AVKit
import AVFoundation

class videoCell: UITableViewCell {

    weak var theVideoPlayer: AVPlayer!
    weak var theVideoPlayerLayer: AVPlayerLayer!
    @IBOutlet weak var theVideoPlayerContainer: UIView!
}
