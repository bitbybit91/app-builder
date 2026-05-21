package com.capitalmonero.app.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class HomeUiState(
    val statusMessage: String = "Ready",
    val isLoading: Boolean = false,
    val error: String? = null,
)

class HomeViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        loadStatus()
    }

    private fun loadStatus() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            // Simulate async work
            _uiState.update { it.copy(statusMessage = "Monero network: Checking…", isLoading = false) }
        }
    }

    fun refresh() {
        loadStatus()
    }
}
