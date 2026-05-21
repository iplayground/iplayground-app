//
//  CommunityFeature+Path.swift
//  Features
//
//  Created by ethanhuang on 2025/8/21.
//
import ComposableArchitecture

extension CommunityFeature {
  @Reducer
  package enum Path {
    case speaker(SpeakerFeature)
  }
}

extension CommunityFeature.Path.State: Equatable {}
extension CommunityFeature.Path.Action: Equatable {}
