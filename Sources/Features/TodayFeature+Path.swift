//
//  TodayFeature+Path.swift
//  Features
//
//  Created by ethanhuang on 2025/8/21.
//
import ComposableArchitecture

extension TodayFeature {
  @Reducer
  package enum Path {
    case speaker(SpeakerFeature)
  }
}

extension TodayFeature.Path.State: Equatable {}
extension TodayFeature.Path.Action: Equatable {}
