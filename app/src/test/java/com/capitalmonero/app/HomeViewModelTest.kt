package com.capitalmonero.app

import app.cash.turbine.test
import com.capitalmonero.app.ui.home.HomeUiState
import com.capitalmonero.app.ui.home.HomeViewModel
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class HomeViewModelTest {

    private val testDispatcher = StandardTestDispatcher()

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state is not loading`() = runTest {
        val viewModel = HomeViewModel()
        viewModel.uiState.test {
            val state = awaitItem()
            assertFalse(state.isLoading)
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun `initial uiState is not null`() = runTest {
        val viewModel = HomeViewModel()
        assertNotNull(viewModel.uiState.value)
    }

    @Test
    fun `HomeUiState default values are correct`() {
        val state = HomeUiState()
        assert(state.statusMessage == "Ready")
        assertFalse(state.isLoading)
        assert(state.error == null)
    }

    @Test
    fun `refresh does not crash`() = runTest {
        val viewModel = HomeViewModel()
        viewModel.refresh()
        testDispatcher.scheduler.advanceUntilIdle()
        assertNotNull(viewModel.uiState.value.statusMessage)
    }
}
